#!/usr/bin/env ocaml
(*------------------------------------------------------------------------------

   UTF-8 Filter 2 (OCaml 4.00)
   Harrison Ainsworth / HXA7241 : 2012-2014

   http://www.hxa.name/tools/

   License: CC0 -- http://creativecommons.org/publicdomain/zero/1.0/

------------------------------------------------------------------------------*)



(* general part ------------------------------------------------------------- *)

module Utf8 :
sig
   type result = Char of string | Invalid of string | EOF | Fail
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
      (bytes.[2] >= '\x90') && (bytes.[2] <= '\xA7'))
   and isTooHigh = (len = 4) &&
      ((bytes.[0] >= '\xF4') && (bytes.[1] >= '\x90') &&
      (bytes.[2]  >= '\x80') && (bytes.[3] >= '\x80')) in

   (isMalformed, isOverlong, isSurrogate,
    isNonchar1a || isNonchar1b || isNonchar2, isTooHigh)


let isComplete bytes =
   let len = String.length bytes in
   ((len = 1) && (bytes.[0] <= '\x7F')) ||
   ((len = 2) && (bytes.[0] <  '\xE0')) ||
   ((len = 3) && (bytes.[0] <  '\xF0')) ||
   ( len = 4)


type result = Char of string | Invalid of string | EOF | Fail


(**
 * Read next valid UTF-8 char or invalid bytes from open file.
 *
 * Effectively partitions the file into valid and invalid parts: so
 * if you just output the Char and Invalid strings again, interleaved
 * in order, you get exactly the original file.
 *
 * Invalid meaning: malformed, overlong, surrogate, non-char, out-of-range.
 * According to: RFC-3629 -- http://tools.ietf.org/html/rfc3629
 * and: Unicode 6.1 -- http://www.unicode.org/versions/Unicode6.1.0/
 *
 * @param fileIn (in(out)) open file to read from
 * @return valid UTF-8 Char (string) | Invalid (string) | EOF | Fail
 *)
let readChar fileIn =

   let rec read bytes =
      (* read and inspect a byte *)
      let bytes = bytes ^ string_of_byte (input_byte fileIn) in
      let (i0, i1, i2, i3, i4) = invalidities bytes in

      (* valid so far: recurse for more, or return char *)
      if not (i0 || i1 || i2 || i3 || i4) then
         if not (isComplete bytes) then read bytes else Char bytes

      (* invalid: return bytes *)
      else
         let len = String.length bytes in
         (* maybe step back a byte in the read-stream *)
         if i0 && (len > 1) then begin
            seek_in fileIn (pos_in fileIn - 1) ;
            Invalid (String.sub bytes 0 (len - 1)) end
         else Invalid bytes in

   try read ""
   with
   | End_of_file -> EOF
   | Sys_error _ -> Fail

end ;;



(* entry point -------------------------------------------------------------- *)

type mode = Check | Filter | Replace ;;

(* standard Unicode 'replacement char' U+FFFD UTF-8:EFBFBD *)
let replacementChar = "\xEF\xBF\xBD" in


(* check if help message needed *)
if ((Array.length Sys.argv) > 1) &&
   ((Sys.argv.(1) = "-?") || (Sys.argv.(1) = "--help")) then

   print_endline "\n\
      \ \ UTF-8 Filter 2 (OCaml 4.00)\n\
      \ \ Harrison Ainsworth / HXA7241 : 2014-05-18\n\
      \ \ http://www.hxa.name\n\
      \n\
      Reads stdin and checks, filters, or replaces its valid UTF-8 content.\n\
      * Check: returns status 0 if OK, else (invalid) returns status 1 and\n\
      \ \ writes to stderr a message.\n\
      * Filter: writes to stdout only the valid UTF-8 content.\n\
      * Replace: writes to stdout the content with invalid parts replaced\n\
      \ \ with 'replacement char's (U+FFFD EFBFBD).\n\
      \n\
      (Invalid UTF-8 meaning: malformed, overlong, surrogate, non-char,\n\
      out-of-range -- according to RFC-3629 and Unicode 6.1.)\n\
      \n\
      Usage:\n  \
        utf8check.ml [-(c|f|r)] < inFile [> outFile]\n\
      -c -- check (default)\n\
      -f -- filter\n\
      -r -- replace\n"

(* otherwise execute *)
else begin

   set_binary_mode_in  stdin  true ;
   set_binary_mode_out stdout true ;
   set_binary_mode_out stderr true ;

   (* choose mode of operation *)
   let mode:mode =
      if (Array.length Sys.argv) > 1 then
         let option1 = Sys.argv.(1) in
         match option1 with
         | "-c" -> Check
         | "-f" -> Filter
         | "-r" -> Replace
         | _    ->
            begin
               prerr_endline ("*** Failed: unrecognized option: " ^ option1) ;
               exit 1
            end
      else Check in

   let invalidCount = ref 0 in

   (* loop through chars until EOF or failure *)
   while true do

      match Utf8.readChar stdin with
      | Utf8.Char c ->
         (match mode with
         | Check   -> ()
         | Filter
         | Replace -> print_string c)

      | Utf8.Invalid s ->
         begin
            let len = String.length s in
            if !invalidCount < (max_int - len) then
               invalidCount := !invalidCount + len ;
            match mode with
            | Check
            | Filter  -> ()
            | Replace -> print_string replacementChar
         end

      | Utf8.EOF ->
         begin
            if !invalidCount <> 0 then
               Printf.eprintf "Invalid byte count: %s%u\n"
                  (if !invalidCount < max_int then "" else "at least ")
                  !invalidCount ;
            exit (match mode with
               | Check   -> if !invalidCount = 0 then 0 else 1
               | Filter
               | Replace -> 0)
         end

      | Utf8.Fail ->
         begin
            prerr_endline "*** Failed: General/system failure." ;
            exit 1
         end
   done

end








(* notes ---------------------------------------------------------------------*)

(*

illegal code points
-------------------

### surrogates ###

high: U+D800 - U+DBFF
low:  U+DC00 - U+DFFF

all: U+D800 - U+DFFF

11011000 00000000 - 1101FFFF FFFFFFFF
11101101 10100000 10000000 - 11101101 10FFFFFF 10FFFFFF

U+D800 = ED A0 80
U+DFFF = ED BF BF


### non-chars ###

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


### too high ###

all at or above:
U-110000  F4 90 80 80

are out of range

*)
