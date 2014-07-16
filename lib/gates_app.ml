open Async.Std

type t = unit


let create () =
  let open NetKAT_Types in
  Async_NetKAT.create (Filter False) (fun _ _ () e -> return None), ()
