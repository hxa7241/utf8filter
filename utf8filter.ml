(*------------------------------------------------------------------------------

   UTF-8 Filter lib (OCaml 4.02)
   Harrison Ainsworth / HXA7241 : 2015

   http://www.hxa.name/tools/

   License: CC0 -- http://creativecommons.org/publicdomain/zero/1.0/

------------------------------------------------------------------------------*)




(* --- types --- *)

type charResult = Char of string | Bad of string | EOF of string

type validness = Invalid | Valid
type condition = Incomplete of validness | Complete of validness




(* --- values --- *)

(* standard Unicode 'replacement char' U+FFFD UTF-8:EFBFBD *)
let _REPLACEMENT_CHAR = "\xEF\xBF\xBD"




(* --- functions --- *)

(* implementation *)

let string_of_char (c:char) : string = String.make 1 c
(*
let string_of_byte (b:int)  : string = String.make 1 (char_of_int (b land 0xFF))
*)


(**
 * Somewhat like a function passed to a fold: it is called repeatedly on a
 * sequence, the params state and octets are ongoing state, and nexto is the
 * next element to process.
 *
 * Invalid sequences end at the next head-byte found -- which therefore must be
 * put back into the stream by the caller, so it can be read again as the start
 * of the next sequence.
 *
 * References:
 * * "Unicode Standard 7.0" ; TheUnicodeConsortium ; 2014 / ISBN-9781936213092 /
 *   book .
 *    * sect 3.9, D92: p124-p126
 * * "RFC 3629" ; TheInternetSociety ; 2003 / txt .
 *
 * Validity as expressed by the unicode standard:
 *
 * byte 0:  00 - 7F (0???????) | C2 - F4
 *    110????? && >= C2
 *    1110????
 *    11110??? && <= F4
 * byte 1:  80 - BF (10??????) unless:
 *    byte 0 = E0 : byte 1 = A0 - BF (101?????)
 *    byte 0 = ED : byte 1 = 80 - 9F (100?????)
 *    byte 0 = F0 : byte 1 = 90 - BF
 *    byte 0 = F4 : byte 1 = 80 - 8F (1000????)
 * byte 2:  80 - BF (10??????)
 * byte 3:  80 - BF (10??????)
 *
 * Validity as expressed by the rfc:
 *
 * UTF8-octets = *( UTF8-char )
 * UTF8-char   = UTF8-1 / UTF8-2 / UTF8-3 / UTF8-4
 * UTF8-1      = %x00-7F
 * UTF8-2      = %xC2-DF UTF8-tail
 * UTF8-3      = %xE0 %xA0-BF UTF8-tail / %xE1-EC 2( UTF8-tail ) /
 *               %xED %x80-9F UTF8-tail / %xEE-EF 2( UTF8-tail )
 * UTF8-4      = %xF0 %x90-BF 2( UTF8-tail ) / %xF1-F3 3( UTF8-tail ) /
 *               %xF4 %x80-8F 2( UTF8-tail )
 * UTF8-tail   = %x80-BF
 *)
let classify (state:validness) (octets:string) (nexto:char) : condition =

   let index = String.length octets
   and nextb = int_of_char nexto
   in

   let validness =
      if (match state with
         (* previously invalid stays invalid *)
         | Invalid when index <> 0 -> false
         | Invalid | Valid ->
            (* is next octet valid ? *)
            begin match index with
            | 0 ->
               (* head-byte (including ASCII) *)
               (nexto <= '\x7F') || ((nexto >= '\xC2') && (nexto <= '\xF4'))
            | 1 ->
               (* first tail-byte has extra constraints *)
               begin match octets.[0] with
               | '\xE0' -> (nextb land 0b11100000) = 0b10100000
               | '\xED' -> (nextb land 0b11100000) = 0b10000000
               | '\xF0' -> (nextb >= 0x90) && (nextb <= 0xBF)
               | '\xF4' -> (nextb land 0b11110000) = 0b10000000
               | _      -> (nextb land 0b11000000) = 0b10000000
               end
            | 2
            | 3 ->
               (* other, simple, tail-bytes *)
               (nextb land 0b11000000) = 0b10000000
            | _ -> false
            end)
      then Valid else Invalid
   in

   let isComplete =
      match validness with
      | Valid ->
         (* length according to head octet has been reached *)
         begin match index with
         | 0 -> nexto      <= '\x7F'
         | 1 -> octets.[0] <  '\xE0'
         | 2 -> octets.[0] <  '\xF0'
         | _ -> true
         end
      | Invalid ->
         (* invalid sequences end at the next head-byte found
            (which must be put back by caller) *)
         (index > 0) && ((nextb land 0b11000000) <> 0b10000000)
   in

   if isComplete then Complete validness else Incomplete validness


(* primary / low-level *)

let readChar (inStream:char Stream.t) : charResult =

   (* accumulate bytes into a chunk *)
   let rec readBytes (state:validness) (bytes:Buffer.t) : charResult =
      (* peek at next byte *)
      match Stream.peek inStream with
      | None      -> EOF (Buffer.contents bytes)
      | Some next ->
         (* consume next byte, and add to chunk *)
         let accumulate () : unit =
            Stream.junk inStream ;
            Buffer.add_string bytes (string_of_char next)
         in
         match classify state (Buffer.contents bytes) next with
         | Incomplete state -> readBytes state (accumulate () ; bytes)
         | Complete Valid   -> Char (accumulate () ; Buffer.contents bytes)
         | Complete Invalid -> Bad (Buffer.contents bytes)
   in

   readBytes Invalid (Buffer.create 8)


(* secondary, for streams *)

let rec checkStream (input:char Stream.t) : bool =

   match readChar input with
   | Char _ -> checkStream input
   | Bad  _ -> false
   | EOF  s -> (String.length s) = 0


let rec scanStream (replacement:string)
   (input:char Stream.t) (output:string->unit) : unit =

   match readChar input with
   | Char s -> (output s           ; scanStream replacement input output)
   | Bad  _ -> (output replacement ; scanStream replacement input output)
   | EOF  s -> output (if (String.length s) = 0 then "" else replacement)


let filterStream : (char Stream.t) -> (string->unit) -> unit =
   scanStream ""


let replaceStream : (char Stream.t) -> (string->unit) -> unit =
   scanStream _REPLACEMENT_CHAR


(* secondary, for strings *)

let check (s:string) : bool = checkStream (Stream.of_string s)


let scanString (replacement:string) (s:string) : string =

   let buf = Buffer.create (String.length s) in
   scanStream replacement (Stream.of_string s) (Buffer.add_string buf) ;
   Buffer.contents buf


let filter : string -> string  = scanString ""


let replace : string -> string = scanString _REPLACEMENT_CHAR
