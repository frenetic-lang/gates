open Async.Std

open NetKAT_Types
open Async_NetKAT


type t

(** [create ()] creates a [Maclist] application, returning the application
 * together with a control object that the user can use to configure the
 * application.
 *)
val create : unit -> t * Policy.t

module type S = sig
  type t

  (** [register_mac t mac] registers [mac] as a valid MAC address on the
   * network, allowing a packet with [mac] as its source MAC address to traverse
   * the network.
   *)
  val register_mac : t -> Packet.dlAddr -> unit Deferred.t

  (** [unregister_mac t mac] invalidates [mac] on the network. Any packet with
   * a source or destination MAC address traversing the network will be dropped.
   *)
  val unregister_mac : t -> Packet.dlAddr -> unit Deferred.t
end

include S with type t := t

(** [flush_operations t] becomes deterined when all previous operations have
 * been processed by the controller or the controller has stopped receiving
 * policy updates. In the former case, the controller will have incorporated the
 * changes into a NetKAT policy that is either in the process of being
 * installed or has already been installed. In the latter case, it is likely
 * that the controller is shutting down.
 *)
val flush_operations : t -> Pipe.Flushed_result.t Deferred.t
