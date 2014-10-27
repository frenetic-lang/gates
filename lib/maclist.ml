open Core.Std
open Async.Std

open NetKAT_Types
open Async_NetKAT

module Mac = struct
  module T = struct
    type t = Packet.dlAddr with sexp

    let compare = compare
    let hash = Hashtbl.hash
  end

  include T
  include Hashable.Make(T)
end


type t = {
  table  : unit Mac.Table.t;
  update : policy Pipe.Writer.t
}

let to_policy table : policy =
  let pred = Hashtbl.fold table ~init:False ~f:(fun ~key ~data acc ->
    Or(Test(EthSrc key), acc))
  in
  Filter pred

let create () =
  let update_r, update_w = Pipe.create () in
  let ctl = { table = Mac.Table.create (); update = update_w } in
  let handler nib send () =
    Deferred.don't_wait_for (Pipe.transfer_id update_r send.Async_NetKAT.update);
    fun e -> return None
  in
  ctl, Policy.create_async (to_policy ctl.table) handler

module type S = sig
  type t

  val register_mac : t -> Packet.dlAddr -> unit Deferred.t
  val unregister_mac : t -> Packet.dlAddr -> unit Deferred.t
end

let register_mac (t:t) (mac:Packet.dlAddr) =
  Hashtbl.replace t.table mac ();
  Pipe.write t.update (to_policy t.table)

let unregister_mac (t:t) (mac:Packet.dlAddr) =
  Hashtbl.remove t.table mac;
  Pipe.write t.update (to_policy t.table)

let flush_operations (t:t) : Pipe.Flushed_result.t Deferred.t =
  Pipe.downstream_flushed t.update
