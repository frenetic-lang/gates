open Core.Std
open Async.Std

let main () : unit =
  let app, ctl = Gates_app.create () in
  Async_NetKAT_Controller.start app ()

let () = never_returns (Scheduler.go_main ~main ())
