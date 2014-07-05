(* Unison file synchronizer: src/fileinfo.ml *)
(* Copyright 1999-2014, Benjamin C. Pierce 

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*)


let debugV = Util.debug "fileinfo+"

let allowSymlinks =
  Prefs.createBoolWithDefault "links"
    "!allow the synchronization of symbolic links (true/false/default)"
    ("When set to {\\tt true}, this flag causes Unison to synchronize \
      symbolic links.  When the flag is set to {\\tt false}, symbolic \
      links will result in an error during update detection.  \
      Ordinarily, when the flag is set to {\\tt default}, symbolic \
      links are synchronized except when one of the hosts is running \
      Windows.  In rare circumstances it may be useful to set the flag \
      manually.")

let symlinksAllowed =
  Prefs.createBool "links-aux" true
    "*Pseudo-preference for internal use only" ""

let init b =
  Prefs.set symlinksAllowed
    (Prefs.read allowSymlinks = `True ||
     (Prefs.read allowSymlinks = `Default && not b))

type typ = [ `ABSENT | `FILE | `DIRECTORY | `SYMLINK ]

let type2string = function
    `ABSENT    -> "nonexistent"
  | `FILE      -> "file"
  | `DIRECTORY -> "dir"
  | `SYMLINK   -> "symlink"

type t = { typ : typ; inode : int; desc : Props.t; osX : Osx.info}

(* Stat function that pays attention to pref for following links             *)
let statFn fromRoot fspath path =
  let fullpath = Fspath.concat fspath path in
  let stats = Fs.lstat fullpath in
  if stats.Unix.LargeFile.st_kind = Unix.S_LNK 
     && fromRoot 
     && Path.followLink path
  then begin
    Fswatch.followLink path;
    try Fs.stat fullpath 
    with Unix.Unix_error((Unix.ENOENT | Unix.ENOTDIR),_,_) ->
      raise (Util.Transient (Printf.sprintf
        "Path %s is marked 'follow' but its target is missing"
        (Fspath.toPrintString fullpath)))
  end else
    stats

let get fromRoot fspath path =
  Util.convertUnixErrorsToTransient
  "querying file information"
    (fun () ->
       try
         let stats = statFn fromRoot fspath path in
         debugV (fun () ->
                   Util.msg "%s: %b %f %f\n"
                     (Fspath.toDebugString (Fspath.concat fspath path))
                     fromRoot stats.Unix.LargeFile.st_ctime stats.Unix.LargeFile.st_mtime);
         let typ =
           match stats.Unix.LargeFile.st_kind with
             Unix.S_REG -> `FILE
           | Unix.S_DIR -> `DIRECTORY
           | Unix.S_LNK ->
               if not fromRoot || Prefs.read symlinksAllowed then
                 `SYMLINK
               else
                 raise
                   (Util.Transient
                      (Format.sprintf "path %s is a symbolic link"
                         (Fspath.toPrintString (Fspath.concat fspath path))))
           | _ ->
               raise (Util.Transient
                        ("path " ^
                         (Fspath.toPrintString (Fspath.concat fspath path)) ^
                         " has unknown file type"))
         in
         let osxInfos = Osx.getFileInfos fspath path typ in
         { typ = typ;
           inode    = (* The inode number is truncated so that
                         it fits in a 31 bit ocaml integer *)
                      stats.Unix.LargeFile.st_ino land 0x3FFFFFFF;
           desc     = Props.get stats osxInfos;
           osX      = osxInfos }
       with
         Unix.Unix_error((Unix.ENOENT | Unix.ENOTDIR),_,_) ->
         { typ = `ABSENT;
           inode    = 0;
           desc     = Props.dummy;
           osX      = Osx.getFileInfos fspath path `ABSENT })

let check fspath path props =
  Util.convertUnixErrorsToTransient
  "checking file information"
    (fun () -> Props.check fspath path (statFn false fspath path) props)

let set fspath path action newDesc =
  let (kind, p) =
    match action with
      `Set defDesc ->
        (* Set the permissions and maybe the other properties                *)
        (* BCP [Nov 2008]: Jerome, in a message to unison-hackers on
           Oct 5, 2005, suggested that this would be better as
              `Set, Props.override (get false fspath path).desc newDesc
           but this does not seem right to me (bcp): if the file was just
           created, then its permissions are something like 0x600, whereas
           the default permissions will set the world read bit, etc. *)
        `Set, Props.override defDesc newDesc
    | `Copy oldPath ->
        (* Set the permissions (using the permissions of the file at         *)
        (* [oldPath] as a default) and maybe the other properties            *)
        `Set, Props.override (get false fspath oldPath).desc newDesc
    | `Update oldDesc ->
        (* Update the different properties (only if necessary)               *)
        `Update,
        Props.override
          (get false fspath path).desc (Props.diff oldDesc newDesc)
  in
  Props.set fspath path kind p;
  check fspath path p

type stamp =
    InodeStamp of int         (* inode number, for Unix systems *)
  | CtimeStamp of float       (* creation time, for windows systems *)
    (* FIX [BCP, 3/07]: The Ctimestamp variant is actually bogus.
      For file transfers, it appears that using the ctime to detect a
      file change is completely ineffective as, when a file is deleted (or
      renamed) and then replaced by another file, the new file inherits the
      ctime of the old file.  It is slightly harmful performancewise, as
      fastcheck expects ctime to be preserved by renaming.  Thus, we should
      probably not use any stamp under Windows. *)

let ignoreInodeNumbers =
  Prefs.createBool "ignoreinodenumbers" false
    "!ignore inode number changes when detecting updates"
    ("When set to true, this preference makes Unison not take advantage \
      of inode numbers during fast update detection. \
      This switch should be used with care, as it \
      is less safe than the standard update detection method, but it \
      can be useful with filesystems which do not support inode numbers.")
let _ = Prefs.alias ignoreInodeNumbers "pretendwin"

let stamp info =
       (* Was "CtimeStamp info.ctime", but this is bogus: Windows
          ctimes are not reliable. *)
  if Prefs.read ignoreInodeNumbers then CtimeStamp 0.0 else
  if Fs.hasInodeNumbers () then InodeStamp info.inode else CtimeStamp 0.0

let ressStamp info = Osx.stamp info.osX

let unchanged fspath path info =
  (* The call to [Util.time] must be before the call to [get] *)
  let t0 = Util.time () in
  let info' = get true fspath path in
  let dataUnchanged =
    Props.same_time info.desc info'.desc
      &&
    stamp info = stamp info'
      &&
    if Props.time info'.desc = t0 then begin
      Unix.sleep 1;
      false
    end else
      true
  in
  (info', dataUnchanged,
   Osx.ressUnchanged info.osX.Osx.ressInfo info'.osX.Osx.ressInfo
     (Some t0) dataUnchanged)

(****)

let get' f =
  Util.convertUnixErrorsToTransient
  "querying file information"
    (fun () ->
       try
         let stats = System.stat f in
         let typ = `FILE in
         let osxInfos = Osx.defaultInfos typ in
         { typ   = typ;
           inode = stats.Unix.LargeFile.st_ino land 0x3FFFFFFF;
           desc  = Props.get stats osxInfos;
           osX   = osxInfos }
       with
         Unix.Unix_error((Unix.ENOENT | Unix.ENOTDIR),_,_) ->
         { typ = `ABSENT;
           inode    = 0;
           desc     = Props.dummy;
           osX      = Osx.defaultInfos `ABSENT })
