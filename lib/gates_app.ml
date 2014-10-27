open Async.Std

open Async_NetKAT


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
  let ctl, pred = Maclist.create () in
  let learn = Learning.create () in
  { maclist = ctl }, seq (filter' pred) learn
