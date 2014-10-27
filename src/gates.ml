open Core.Std
open Async.Std

let main () : unit =
  let open Deferred in
  let ctl, app = Gates_app.create () in
  don't_wait_for (ignore (Async_NetKAT_Controller.start app ()))

let () = never_returns (Scheduler.go_main ~main ())
