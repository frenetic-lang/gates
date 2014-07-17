open Async.Std

type t = {
  maclist : Maclist.t;
}

let register_mac (t:t) =
  Maclist.register_mac t.maclist

let unregister_mac (t:t) =
  Maclist.unregister_mac t.maclist

let flush_operations (t:t) =
  Maclist.flush_operations t.maclist

let create () =
  let ctl, app = Maclist.create () in
  { maclist = ctl }, app
