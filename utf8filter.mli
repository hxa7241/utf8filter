(*------------------------------------------------------------------------------

   UTF-8 Filter lib (OCaml 4.02)
   Harrison Ainsworth / HXA7241 : 2015

   http://www.hxa.name/tools/

   License: CC0 -- http://creativecommons.org/publicdomain/zero/1.0/

------------------------------------------------------------------------------*)




(* --- types --- *)

type charResult = Char of string | Bad of string | EOF of string




(* --- values --- *)

val _REPLACEMENT_CHAR : string




(* --- functions --- *)

(* primary / low-level *)

(**
 * Read next valid UTF-8 char or invalid bytes from open file.
 *
 * Effectively partitions the file into valid and invalid parts: so
 * if you just output the Char and Bad strings again, interleaved
 * in order (and the EOF string at the end), you get exactly the
 * original file.
 *
 * According to: RFC-3629 -- http://tools.ietf.org/html/rfc3629
 * and: Unicode 7.0 -- http://www.unicode.org/versions/Unicode7.0.0/
 *
 * @param byte stream to read from
 * @return valid UTF-8 Char | Bad | EOF
 *)
val readChar : (char Stream.t) -> charResult


(* secondary, for streams *)

(** Check if all valid. *)
val checkStream   : (char Stream.t) -> bool

(** Remove all invalid byte sequences. *)
val filterStream  : (char Stream.t) -> (string->unit) -> unit

(** Replace all invalid byte sequences with replacement chars. *)
val replaceStream : (char Stream.t) -> (string->unit) -> unit


(* secondary, for strings *)

(** Check if all valid. *)
val check   : string -> bool

(** Remove all invalid byte sequences. *)
val filter  : string -> string

(** Replace all invalid byte sequences with replacement chars. *)
val replace : string -> string
