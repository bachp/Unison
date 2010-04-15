(*
This file is taken from the Objective Caml standard library.
Some functions have been added to suite Unison needs.
*)
(***********************************************************************)
(*                                                                     *)
(*                           Objective Caml                            *)
(*                                                                     *)
(*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         *)
(*                                                                     *)
(*  Copyright 1996 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the GNU Library General Public License, with    *)
(*  the special exception on linking described in file ../LICENSE.     *)
(*                                                                     *)
(***********************************************************************)

module type OrderedType =
  sig
    type t
    val compare: t -> t -> int
  end

module type S =
  sig
    type key
    type +'a t
    val empty: 'a t
    val is_empty: 'a t -> bool
    val add: key -> 'a -> 'a t -> 'a t
    val find: key -> 'a t -> 'a
    val findi: key -> 'a t -> key * 'a
    val remove: key -> 'a t -> 'a t
    val mem:  key -> 'a t -> bool
    val iter: (key -> 'a -> unit) -> 'a t -> unit
    val map: ('a -> 'b) -> 'a t -> 'b t
    val mapi: (key -> 'a -> 'b) -> 'a t -> 'b t
    val mapii: (key -> 'a -> key * 'b) -> 'a t -> 'b t
    val fold: (key -> 'a -> 'b -> 'b) -> 'a t -> 'b -> 'b
    val compare: ('a -> 'a -> int) -> 'a t -> 'a t -> int
    val equal: ('a -> 'a -> bool) -> 'a t -> 'a t -> bool
    val validate: 'a t -> [`Ok | `Duplicate of key | `Invalid of key * key]
  end

module Make(Ord: OrderedType) = struct

    type key = Ord.t

    type 'a t =
        Empty
      | Node of 'a t * key * 'a * 'a t * int

    let height = function
        Empty -> 0
      | Node(_,_,_,_,h) -> h

    let create l x d r =
      let hl = height l and hr = height r in
      Node(l, x, d, r, (if hl >= hr then hl + 1 else hr + 1))

    let bal l x d r =
      let hl = match l with Empty -> 0 | Node(_,_,_,_,h) -> h in
      let hr = match r with Empty -> 0 | Node(_,_,_,_,h) -> h in
      if hl > hr + 2 then begin
        match l with
          Empty -> invalid_arg "Map.bal"
        | Node(ll, lv, ld, lr, _) ->
            if height ll >= height lr then
              create ll lv ld (create lr x d r)
            else begin
              match lr with
                Empty -> invalid_arg "Map.bal"
              | Node(lrl, lrv, lrd, lrr, _)->
                  create (create ll lv ld lrl) lrv lrd (create lrr x d r)
            end
      end else if hr > hl + 2 then begin
        match r with
          Empty -> invalid_arg "Map.bal"
        | Node(rl, rv, rd, rr, _) ->
            if height rr >= height rl then
              create (create l x d rl) rv rd rr
            else begin
              match rl with
                Empty -> invalid_arg "Map.bal"
              | Node(rll, rlv, rld, rlr, _) ->
                  create (create l x d rll) rlv rld (create rlr rv rd rr)
            end
      end else
        Node(l, x, d, r, (if hl >= hr then hl + 1 else hr + 1))

    let empty = Empty

    let is_empty = function Empty -> true | _ -> false

    let rec add x data = function
        Empty ->
          Node(Empty, x, data, Empty, 1)
      | Node(l, v, d, r, h) ->
          let c = Ord.compare x v in
          if c = 0 then
            Node(l, x, data, r, h)
          else if c < 0 then
            bal (add x data l) v d r
          else
            bal l v d (add x data r)

    let rec find x = function
        Empty ->
          raise Not_found
      | Node(l, v, d, r, _) ->
          let c = Ord.compare x v in
          if c = 0 then d
          else find x (if c < 0 then l else r)

    let rec findi x = function
        Empty ->
          raise Not_found
      | Node(l, v, d, r, _) ->
          let c = Ord.compare x v in
          if c = 0 then (v, d)
          else findi x (if c < 0 then l else r)

    let rec mem x = function
        Empty ->
          false
      | Node(l, v, d, r, _) ->
          let c = Ord.compare x v in
          c = 0 || mem x (if c < 0 then l else r)

    let rec min_binding = function
        Empty -> raise Not_found
      | Node(Empty, x, d, r, _) -> (x, d)
      | Node(l, x, d, r, _) -> min_binding l

    let rec remove_min_binding = function
        Empty -> invalid_arg "Map.remove_min_elt"
      | Node(Empty, x, d, r, _) -> r
      | Node(l, x, d, r, _) -> bal (remove_min_binding l) x d r

    let merge t1 t2 =
      match (t1, t2) with
        (Empty, t) -> t
      | (t, Empty) -> t
      | (_, _) ->
          let (x, d) = min_binding t2 in
          bal t1 x d (remove_min_binding t2)

    let rec remove x = function
        Empty ->
          Empty
      | Node(l, v, d, r, h) ->
          let c = Ord.compare x v in
          if c = 0 then
            merge l r
          else if c < 0 then
            bal (remove x l) v d r
          else
            bal l v d (remove x r)

    let rec iter f = function
        Empty -> ()
      | Node(l, v, d, r, _) ->
          iter f l; f v d; iter f r

    let rec map f = function
        Empty               -> Empty
      | Node(l, v, d, r, h) ->
          let l' = map f l in
          let d' = f d in
          let r' = map f r in
          Node(l', v, d', r', h)

    let rec mapi f = function
        Empty               -> Empty
      | Node(l, v, d, r, h) ->
          let l' = mapi f l in
          let d' = f v d in
          let r' = mapi f r in
          Node(l', v, d', r', h)

    let rec mapii f = function
        Empty               -> Empty
      | Node(l, v, d, r, h) ->
          let l' = mapii f l in
          let (v', d') = f v d in
          if v' != v && Ord.compare v v' <> 0 then invalid_arg "Map.mapii";
          let r' = mapii f r in
          Node(l', v', d', r', h)

    let rec fold f m accu =
      match m with
        Empty -> accu
      | Node(l, v, d, r, _) ->
          fold f l (f v d (fold f r accu))

    type 'a enumeration = End | More of key * 'a * 'a t * 'a enumeration

    let rec cons_enum m e =
      match m with
        Empty -> e
      | Node(l, v, d, r, _) -> cons_enum l (More(v, d, r, e))

    let compare cmp m1 m2 =
      let rec compare_aux e1 e2 =
          match (e1, e2) with
          (End, End) -> 0
        | (End, _)  -> -1
        | (_, End) -> 1
        | (More(v1, d1, r1, e1), More(v2, d2, r2, e2)) ->
            let c = Ord.compare v1 v2 in
            if c <> 0 then c else
            let c = cmp d1 d2 in
            if c <> 0 then c else
            compare_aux (cons_enum r1 e1) (cons_enum r2 e2)
      in compare_aux (cons_enum m1 End) (cons_enum m2 End)

    let equal cmp m1 m2 =
      let rec equal_aux e1 e2 =
          match (e1, e2) with
          (End, End) -> true
        | (End, _)  -> false
        | (_, End) -> false
        | (More(v1, d1, r1, e1), More(v2, d2, r2, e2)) ->
            Ord.compare v1 v2 = 0 && cmp d1 d2 &&
            equal_aux (cons_enum r1 e1) (cons_enum r2 e2)
      in equal_aux (cons_enum m1 End) (cons_enum m2 End)

    let val_combine r r' =
      match r, r' with
        `Ok         ,  _  -> r'
      | `Duplicate _, `Ok -> r
      | `Duplicate _,  _  -> r'
      |  _          ,  _  -> r

    let rec validate_both v m v' =
      match m with
        Empty ->
          let c = Ord.compare v v' in
          if c < 0 then `Ok
          else if c = 0 then `Duplicate v
          else `Invalid (v, v')
      | Node (l, v'', _, r, _) ->
          val_combine (validate_both v l v'') (validate_both v'' r v')

    let rec validate_left m v =
      match m with
        Empty ->
          `Ok
      | Node (l, v', _, r, _) ->
          val_combine (validate_left l v') (validate_both v' r v)

    let rec validate_right v m =
      match m with
        Empty ->
          `Ok
      | Node (l, v', _, r, _) ->
          val_combine (validate_both v l v') (validate_right v' r)

    let validate m =
      match m with
        Empty ->
          `Ok
      | Node (l, v, _, r, _) ->
          val_combine (validate_left l v) (validate_right v r)
end
