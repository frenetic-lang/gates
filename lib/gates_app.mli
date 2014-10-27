open Async.Std

open Async_NetKAT


type t

(** [create ()] creates a [Gates_app] application, returning the application
 * together with a control object that the user can use to configure the
 * application.
 *)
val create : unit -> t * Policy.t

include Maclist.S with type t := t

(** [flush_operations t] becomes deterined when all previous operations have
 * been processed by the controller or the controller has stopped receiving
 * policy updates. In the former case, the controller will have incorporated the
 * changes into a NetKAT policy that is either in the process of being
 * installed or has already been installed. In the latter case, it is likely
 * that the controller is shutting down.
 *)
val flush_operations : t -> Pipe.Flushed_result.t Deferred.t
