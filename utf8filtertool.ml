(*------------------------------------------------------------------------------

   UTF-8 Filter tool (OCaml 4.02)
   Harrison Ainsworth / HXA7241 : 2015

   http://www.hxa.name/tools/

   License: CC0 -- http://creativecommons.org/publicdomain/zero/1.0/

------------------------------------------------------------------------------*)




try

   (* check if help message needed *)
   if ((Array.length Sys.argv) > 1) &&
      ((Sys.argv.(1) = "-?") || (Sys.argv.(1) = "--help"))

   (* print help *)
   then
      print_endline "\n\
         \ \ UTF-8 Filter (OCaml 4.02)\n\
         \ \ Harrison Ainsworth / HXA7241 : 2015-05-16\n\
         \ \ http://www.hxa.name\n\
         \n\
         Reads stdin and checks, filters, or replaces it as UTF-8 content.\n\
         * Check: returns status 0 if all content valid UTF-8, \
           else status 1.\n\
         * Filter: writes to stdout only the valid UTF-8 content.\n\
         * Replace: writes to stdout the valid UTF-8 content with invalid\n\
         \ \ parts replaced with standard replacement chars (U+FFFD \
           U8+EFBFBD).\n\
         \n\
         (According to RFC-3629 and Unicode 7.0.).\n\
         \n\
         Usage:\n\
         \ \ utf8filter [-(c|f|r)] [< inFile] [> outFile]\n\
         -c  check (default)\n\
         -f  filter\n\
         -r  replace\n"

   (* execute *)
   else begin

      let fail (message:string) : 'a =
         begin
            prerr_endline ("*** Failed: " ^ message ^ ".") ;
            exit 1
         end
      in

      set_binary_mode_in  stdin  true ;
      set_binary_mode_out stdout true ;
      set_binary_mode_out stderr true ;

      let stdinStream = Stream.of_channel stdin in

      try
         (* dispatch on options *)
         match Array.sub Sys.argv 1 ((Array.length Sys.argv) - 1) with

         | [||] (* default *)
         | [|"-c"|] ->
            if Utf8filter.checkStream stdinStream
            then  prerr_endline "UTF-8 check: OK"
            else (prerr_endline "UTF-8 check: invalid" ; exit 1)
         | [|"-f"|] -> Utf8filter.filterStream  stdinStream print_string
         | [|"-r"|] -> Utf8filter.replaceStream stdinStream print_string

         | _ as a   ->
            fail (
               match a with
               | [|s|] -> "unrecognized option: " ^ s
               | _     -> "unrecognized command -- too many options/items"
            )
      with
      | Sys_error s -> fail ("system IO failure: " ^ s)

   end

with
| e -> prerr_string "*** General failure: " ; raise e
