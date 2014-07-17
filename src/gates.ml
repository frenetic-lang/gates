open Core.Std
open Async.Std

let main () : unit =
  let ctl, app = Gates_app.create () in
  Async_NetKAT_Controller.start app ()

let () = never_returns (Scheduler.go_main ~main ())
