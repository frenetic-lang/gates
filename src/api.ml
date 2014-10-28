open Async.Std
open Core.Std
open Cohttp_async

let static_handler ?content_type filename = fun _ _ _ ->
  let headers = match content_type with
    | None -> None
    | Some(typ) ->
      Some(Cohttp.Header.init_with "Content-type" typ) in
  Server.respond_with_file ?headers filename

let string_handler str = fun _ _ _ ->
  Server.respond_with_string str

let not_found_handler = fun _ _ _ ->
  Server.respond_with_string ~code:(`Code 404) "Not found"

let routes_to_handler rs =
  let table = List.map rs ~f:(fun (route, handler) ->
    (Re_posix.(compile (re ("^" ^ route ^ "$"))), handler)) 
  in
  let open Cohttp in
  let rec loop uri = function
    | (re, handler)::t' ->
      begin try
        let h = handler Re.(get_all (exec re uri)) in
        fun body addr request ->  begin
          let meth = request.Request.meth in
          Printf.printf "[server] 200 %s %s\n%!" (Code.string_of_method meth) uri;
          h body addr request
        end
      with Not_found -> 
        loop uri t'
      end
    | [] ->
      fun _ _ request ->
        let meth = request.Request.meth in
        Printf.printf "[server] 404 %s %s\n%!" (Code.string_of_method meth) uri;
        Server.respond_with_string ~code:(`Code 404)
          "Not found" 
  in
  fun ~body addr request ->
    (loop Uri.(pct_decode (path (Cohttp.Request.uri request))) table) body addr request

let start ?max_connections ?max_pending_connections
    ?buffer_age_limit ?on_handler_error ?(port=8080) gates ctl =
  let open Cohttp in
  let routes = [
    ("/discovery", fun _ _ _ request ->
      match request.Request.meth with
      | `Other "ENABLE"  ->
        Async_NetKAT_Controller.enable_discovery ctl >>= fun () ->
        Server.respond_with_string ~code:`OK "enabled"
      | `Other "DISABLE" ->
        Async_NetKAT_Controller.disable_discovery ctl >>= fun () ->
        Server.respond_with_string ~code:`OK "disabled"
      | _ ->
        Server.respond_with_string ~code:(`Code 405) "Method not allwoed"
    );
    ("/maclist/([0-9a-fA-F]{2}(:[0-9a-fA-F]{2}){5})", fun parts _ _ request ->
      let mac_str = Array.get parts 1 in
      let mac = Packet.mac_of_string mac_str in
      match request.Request.meth with
      | `POST   ->
        Gates_app.register_mac gates mac
        >>= fun () -> Gates_app.flush_operations gates
        >>= fun r -> begin match r with
          | `Ok -> Server.respond_with_string
              ~code:`OK (Printf.sprintf "allowed %s" mac_str)
          | `Reader_closed -> Server.respond_with_string
              ~code:`Internal_server_error "update pipe closed"
        end
      | `DELETE ->
        Gates_app.unregister_mac gates mac
        >>= fun () -> Gates_app.flush_operations gates
        >>= fun r -> begin match r with
          | `Ok -> Server.respond_with_string
              ~code:`OK (Printf.sprintf "disallowed %s" mac_str)
          | `Reader_closed -> Server.respond_with_string
              ~code:`Internal_server_error "update pipe closed"
        end
      | _ ->
        Server.respond_with_string ~code:(`Code 405) "Method not allwoed"
    )
  ]
  in
  let open Async.Std in
  Server.create ?max_connections ?max_pending_connections
    ?buffer_age_limit ?on_handler_error
    (Tcp.on_port port) (routes_to_handler routes)
