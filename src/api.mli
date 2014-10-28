open Async.Std
open Cohttp_async

(** Start an embedded HTTP server that allows users to configure the controller
    and the Gates application using an HTTP Client. The following endpoints and
    methods are now supported:

        /discovery [ENABLE|DISABLE] <no body>
          ENABLE    - enable topology discovery
          DISABLE   - disable topology discovery

        /maclist/<mac> [POST|DELETE] <no body>
          POST      - Add <mac> to the whitelist
          DELETE    - Remove <mac> from the whitelist

    Note that the MAC address should be in the form xx:xx:xx:xx:xx:xx *)
val start :
  ?max_connections:int ->
  ?max_pending_connections:int ->
  ?buffer_age_limit: Writer.buffer_age_limit ->
  ?on_handler_error:[ `Call of Socket.Address.Inet.t -> exn  -> unit
                    | `Ignore
                    | `Raise ] ->
  ?port:int
  -> Gates_app.t
  -> Async_NetKAT_Controller.t
  -> (Socket.Address.Inet.t, int) Server.t Deferred.t
