(* Unison file synchronizer: src/os.mli *)
(* Copyright 1999-2014, Benjamin C. Pierce (see COPYING for details) *)

val myCanonicalHostName : unit -> string

val tempPath : ?fresh:bool -> Fspath.t -> Path.local -> Path.local
val tempFilePrefix : string
val isTempFile : string -> bool
val includeInTempNames : string -> unit

val exists : Fspath.t -> Path.local -> bool

val createUnisonDir : unit -> unit
val fileInUnisonDir : string -> System.fspath
val unisonDir : System.fspath

val childrenOf : Fspath.t -> Path.local -> Name.t list
val readLink : Fspath.t -> Path.local -> string
val symlink : Fspath.t -> Path.local -> string -> unit

val rename : string -> Fspath.t -> Path.local -> Fspath.t -> Path.local -> unit
val createDir : Fspath.t -> Path.local -> Props.t -> unit
val delete : Fspath.t -> Path.local -> unit

(* We define a new type of fingerprints here so that clients of
   Os.fingerprint do not need to worry about whether files have resource
   forks, or whatever, that need to be fingerprinted separately.  They can
   sensibly be compared for equality using =.  Internally, a fullfingerprint
   is a pair of the main file's fingerprint and the resource fork fingerprint,
   if any. *)
type fullfingerprint
val fullfingerprint_to_string : fullfingerprint -> string
val reasonForFingerprintMismatch : fullfingerprint -> fullfingerprint -> string
val fullfingerprint_dummy : fullfingerprint
val fullfingerprintHash : fullfingerprint -> int
val fullfingerprintEqual : fullfingerprint -> fullfingerprint -> bool

(* Use this function if the file may change during fingerprinting *)
val safeFingerprint :
  Fspath.t -> Path.local -> (* coordinates of file to fingerprint *)
  Fileinfo.t ->             (* old fileinfo *)
  fullfingerprint option -> (* fingerprint corresponding to the old fileinfo *)
  Fileinfo.t * fullfingerprint
                            (* current fileinfo, fingerprint and fork info *)
val fingerprint :
  Fspath.t -> Path.local -> (* coordinates of file to fingerprint *)
  Fileinfo.t ->             (* old fileinfo *)
  fullfingerprint           (* current fingerprint *)

val pseudoFingerprint :
  Path.local             -> (* path of file to "fingerprint" *)
  Uutil.Filesize.t       -> (* size of file to "fingerprint" *)
  fullfingerprint           (* pseudo-fingerprint of this file (containing just
                               the file's length and path) *)

val isPseudoFingerprint :
  fullfingerprint -> bool
