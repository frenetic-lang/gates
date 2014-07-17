open Core.Std
open Async.Std

open NetKAT_Types

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
  table  : switch_port option Mac.Table.t;
  update : policy Pipe.Writer.t
}

let to_policy table : policy =
  let init = (False, False) in
  let src, dst = Hashtbl.fold table ~init ~f:(fun ~key:mac ~data:loc (src,dst) ->
    let src' = match loc with
    | None ->
      Test (EthSrc mac)
    | Some(sw_id, pt_id) ->
      let sw_t = Test (Switch sw_id) in
      let pt_t = Test (Location (Physical pt_id)) in
      Or (And (sw_t    , And (pt_t, Test (EthSrc mac))),
          And (Neg sw_t, Test (EthSrc mac)))
    in
    Or (src', src), Or (Test (EthDst mac), dst))
  in
  Filter (And (src, dst))

let create () =
  let update_r, update_w = Pipe.create () in
  let ctl = { table = Mac.Table.create (); update = update_w } in
  let handler nib send () =
    Deferred.don't_wait_for (Pipe.transfer_id update_r send.Async_NetKAT.update);
    fun e -> return None
  in
  ctl, Async_NetKAT.create_async (to_policy ctl.table) handler

module type S = sig
  type t

  val register_mac : t -> ?loc:switch_port -> Packet.dlAddr -> unit Deferred.t
  val unregister_mac : t -> Packet.dlAddr -> unit Deferred.t
end

let register_mac (t:t) ?loc (mac:Packet.dlAddr) =
  Hashtbl.replace t.table mac loc;
  Pipe.write t.update (to_policy t.table)

let unregister_mac (t:t) (mac:Packet.dlAddr) =
  Hashtbl.remove t.table mac;
  Pipe.write t.update (to_policy t.table)

let flush_operations (t:t) : Pipe.Flushed_result.t Deferred.t =
  Pipe.downstream_flushed t.update

