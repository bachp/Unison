(***********************************************************************)
(*                                                                     *)
(*                           Objective Caml                            *)
(*                                                                     *)
(*            Xavier Leroy, projet Cristal, INRIA Rocquencourt         *)
(*                                                                     *)
(*  Copyright 1996 Institut National de Recherche en Informatique et   *)
(*  en Automatique.  All rights reserved.  This file is distributed    *)
(*  under the terms of the GNU Library General Public License.         *)
(*                                                                     *)
(***********************************************************************)

(* Modified for Unison *)


(* Module [Printf]: formatting printing functions *)

val fprintf: out_channel -> (unit->unit) -> ('a, out_channel, unit) format -> 'a
        (* [fprintf outchan doafter format arg1 ... argN] formats the arguments
           [arg1] to [argN] according to the format string [format],
           outputs the resulting string on the channel [outchan], and then
           executes the thunk [doafter].

           The format is a character string which contains two types of
           objects:  plain  characters, which are simply copied to the
           output channel, and conversion specifications, each of which
           causes  conversion and printing of one argument.

           Conversion specifications consist in the [%] character, followed
           by optional flags and field widths, followed by one conversion
           character. The conversion characters and their meanings are:
-          [d] or [i]: convert an integer argument to signed decimal
-          [u]: convert an integer argument to unsigned decimal
-          [x]: convert an integer argument to unsigned hexadecimal,
                using lowercase letters.
-          [X]: convert an integer argument to unsigned hexadecimal,
                using uppercase letters.
-          [o]: convert an integer argument to unsigned octal.
-          [s]: insert a string argument
-          [c]: insert a character argument
-          [f]: convert a floating-point argument to decimal notation,
                in the style [dddd.ddd]
-          [e] or [E]: convert a floating-point argument to decimal notation,
                in the style [d.ddd e+-dd] (mantissa and exponent)
-          [g] or [G]: convert a floating-point argument to decimal notation,
                in style [f] or [e], [E] (whichever is more compact)
-          [b]: convert a boolean argument to the string [true] or [false]
-          [a]: user-defined printer. Takes two arguments and apply the first
                one to [outchan] (the current output channel) and to the second
                argument. The first argument must therefore have type
                [out_channel -> 'b -> unit] and the second ['b].
                The output produced by the function is therefore inserted
                in the output of [fprintf] at the current point.
-          [t]: same as [%a], but takes only one argument (with type
                [out_channel -> unit]) and apply it to [outchan].
-          [%]: take no argument and output one [%] character.
-          Refer to the C library [printf] function for the meaning of
           flags and field width specifiers.

           Warning: if too few arguments are provided,
           for instance because the [printf] function is partially
           applied, the format is immediately printed up to
           the conversion of the first missing argument; printing
           will then resume when the missing arguments are provided.
           For example, [List.iter (printf "x=%d y=%d " 1) [2;3]]
           prints [x=1 y=2 3] instead of the expected
           [x=1 y=2 x=1 y=3].  To get the expected behavior, do
           [List.iter (fun y -> printf "x=%d y=%d " 1 y) [2;3]]. *)

val printf: (unit->unit) -> ('a, out_channel, unit) format -> 'a
        (* Same as [fprintf], but output on [stdout]. *)

val eprintf: (unit->unit) -> ('a, out_channel, unit) format -> 'a
        (* Same as [fprintf], but output on [stderr]. *)

