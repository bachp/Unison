(* Unison file synchronizer: src/name.mli *)
(* Copyright 1999-2014, Benjamin C. Pierce (see COPYING for details) *)

type t

val fromString : string -> t
val toString : t -> string

val compare : t -> t -> int
val eq : t -> t -> bool
val hash : t -> int

val normalize : t -> t

val badEncoding : t -> bool
val badFile : t -> bool
