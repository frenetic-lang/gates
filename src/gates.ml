open Core.Std
open Async.Std

module C = Async_NetKAT_Controller


let main () : unit =
  let open Deferred in
  let gates, app = Gates_app.create () in
  let thread = C.start app ()
    >>= fun ctl -> ignore (Api.start gates ctl)
  in
  don't_wait_for thread

let () = never_returns (Scheduler.go_main ~main ())
