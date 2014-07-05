(* Unison file synchronizer: src/lock.mli *)
(* Copyright 1999-2014, Benjamin C. Pierce (see COPYING for details) *)

(* A simple utility module for setting and releasing inter-process locks
   using entries in the filesystem. *)

val acquire : System.fspath -> bool
val release : System.fspath -> unit
val is_locked : System.fspath -> bool
