#!/usr/bin/env ocaml
(*------------------------------------------------------------------------------

   UTF-8 filter (OCaml 4.00)
   Harrison Ainsworth / HXA7241 : 2013

   http://www.hxa.name/tools/

   License: CC0 -- http://creativecommons.org/publicdomain/zero/1.0/

------------------------------------------------------------------------------*)



module Utf8 :
sig
   type result = Char of string | EOF | Fail
   val readChar : in_channel -> result
end =

struct

let string_of_byte b = String.make 1 (char_of_int b)


let invalidities bytes =
   let len  = String.length bytes in
   let last = len - 1 in

   let isMalformed = ((len > 1) &&
      ((bytes.[last] < '\x80') || (bytes.[last] > '\xBF'))) ||
      ((len = 1) && (((bytes.[last] > '\x7F') &&
      (bytes.[last] < '\xC2')) || (bytes.[last] > '\xF4')))
   and isOverlong = (len = 2) &&
      (((bytes.[0] = '\xE0') && (bytes.[1] < '\xA0')) ||
      ((bytes.[0] = '\xF0') && (bytes.[1] < '\x90')))
   and isSurrogate = (len = 2) &&
      ((bytes.[0] = '\xED') && (bytes.[1] >= '\xA0'))
   and isNonchar1a = (len = 3) &&
      ((bytes.[0] = '\xEF') && (bytes.[1] = '\xBF') &&
      (bytes.[2] >= '\xBE'))
   and isNonchar1b =
      if len <> 4 then false else
         let p = (((int_of_char bytes.[1]) / 16) mod 4) +
            ((int_of_char bytes.[0]) mod 7) * 4 in
         (p >= 0x01) && (p <= 0x10) &&
            (bytes.[2] = '\xBF') && (bytes.[3] >= '\xBE') &&
            (((int_of_char bytes.[1]) mod 0x10) = 0x0F) &&
            (((int_of_char bytes.[0]) / 16) = 0x0F)
   and isNonchar2 = (len = 3) &&
      ((bytes.[0] = '\xEF') && (bytes.[1] = '\xB7') &&
      (bytes.[2] >= '\x90') && (bytes.[2] <= '\xA7')) in

   (isMalformed, isOverlong, isSurrogate,
    isNonchar1a || isNonchar1b || isNonchar2)


let isComplete bytes =
   let len = String.length bytes in
   ((len = 1) && (bytes.[0] <= '\x7F')) ||
   ((len = 2) && (bytes.[0] <  '\xE0')) ||
   ((len = 3) && (bytes.[0] <  '\xF0')) ||
   ( len = 4)


type result = Char of string | EOF | Fail


(**
 * Read next valid UTF-8 char from open file.
 * (Discards invalid chars until (moving forward) a valid one is found.)
 *
 * Invalid meaning: malformed, overlong, surrogate, non-char.
 *
 * According to: RFC-3629 -- http://tools.ietf.org/html/rfc3629
 * and: Unicode 6.1 -- http://www.unicode.org/versions/Unicode6.1.0/
 *
 * @param fileIn (in(out)) open file to read from
 * @return valid UTF-8 char (string) | EOF | Fail
 *)
let readChar fileIn =

   let append bytes = bytes ^ string_of_byte (input_byte fileIn) in

   let check bytes =
      let (i0, i1, i2, i3) = invalidities bytes in
      if i0 || i1 || i2 || i3 then begin
         (* reset read-char state *)
         if i0 && (String.length bytes > 1) then
            seek_in fileIn (pos_in fileIn - 1) ;
         "" end
      else bytes in

   let rec read bytes = 
      let bytes = check (append bytes) in
      if not (isComplete bytes) then read bytes else Char bytes in

   try read ""
   with
   | End_of_file -> EOF
   | Sys_error _ -> Fail


(* (* or, imperatively: *)
let readChar fileIn =

   try
      let bytes = ref "" in

      (* until complete char *)
      while not (isComplete !bytes) do
         (* read and accumulate byte *)
         bytes := !bytes ^ string_of_byte (input_byte fileIn) ;

         (* invalid resets read-char state *)
         let (i0, i1, i2, i3) = invalidities !bytes in
         if i0 || i1 || i2 || i3 then begin
            if i0 && (String.length !bytes > 1) then
               seek_in fileIn (pos_in fileIn - 1) ;
            bytes := ""
         end
      done ;

      Char !bytes

   with
   | End_of_file -> EOF
   | Sys_error _ -> Fail *)

end ;;



(* entry point -------------------------------------------------------------- *)

(* check if help message needed *)
if ((Array.length Sys.argv) > 1) &&
   ((Sys.argv.(1) = "-?") || (Sys.argv.(1) = "--help")) then

   print_endline "\n  \
        UTF-8 filter (OCaml 4.00)\n  \
        Harrison Ainsworth / HXA7241 : 2013-01-18\n  \
        http://www.hxa.name/\n\
      \n\
      Reads stdin, and writes to stdout only the valid UTF-8 content.\n\
      (Invalid meaning: malformed, overlong, surrogate, non-char --\n\
      according to RFC-3629 and Unicode 6.1.)\n\
      \n\
      usage:\n  \
        utf8filter.ml < inFile > outFile\n"

(* otherwise execute *)
else begin

   set_binary_mode_in  stdin  true ;
   set_binary_mode_out stdout true ;

   (* loop through chars until EOF or failure *)
   while true do
      match Utf8.readChar stdin with
      | Utf8.Char c -> print_string c
      | Utf8.EOF    -> exit 0
      | Utf8.Fail   -> exit 1
   done

end








(* notes ---------------------------------------------------------------------*)

(*

illegal code points
-------------------

### surrogates

high: U+D800 - U+DBFF
low:  U+DC00 - U+DFFF

all: U+D800 - U+DFFF

11011000 00000000 - 1101FFFF FFFFFFFF
11101101 10100000 10000000 - 11101101 10FFFFFF 10FFFFFF

U+D800 = ED A0 80
U+DFFF = ED BF BF


### non-chars

1a and 1b:

U+FFFE and U+FFFF (3 bytes)
U+1FFFE and U+1FFFF (4 bytes)
...
U+10FFFE and U+10FFFF


11111111 11111111
11101111 10111111 10111111  EF BF BF

00000001 11111111 11111111
11110000 10011111 10111111 10111111  F0 9F BF BF
...
00010000 11111111 11111111
11110100 10001111 10111111 10111111  F4 8F BF BF

   09 0A 0B
18 19 1A 1B
28 29 2A 2B
38 39 3A 3B
48

F0-F4 & 8-B

2:

U+FDD0 - U+FDEF

11111101 11010000 - 11111101 11101111
11101111 10110111 10010000 - 11101111 10110111 10101111
EF B7 90 - EF B7 A7

*)
