open Core.Std
open Async.Std

module C = Async_NetKAT_Controller


let main () : unit =
  let open Deferred in
  let ctl, app = Gates_app.create () in
  let thread = C.start app ()
    >>= fun t ->
      C.enable_discovery t >>= fun () ->
      List.iter ~f:(Gates_app.register_mac ctl) [1L; 2L; 3L]
  in
  don't_wait_for thread

let () = never_returns (Scheduler.go_main ~main ())
