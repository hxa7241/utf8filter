(*------------------------------------------------------------------------------

   UTF-8 Filter 3 (OCaml 4.02)
   Harrison Ainsworth / HXA7241 : 2015

   http://www.hxa.name/tools/

   License: CC0 -- http://creativecommons.org/publicdomain/zero/1.0/

------------------------------------------------------------------------------*)




type mode = Check | Filter | Replace ;;


try

   (* check if help message needed *)
   if ((Array.length Sys.argv) > 1) &&
      ((Sys.argv.(1) = "-?") || (Sys.argv.(1) = "--help"))

   (* print help *)
   then
      print_endline "\n\
         \ \ UTF-8 Filter (OCaml 4.02)\n\
         \ \ Harrison Ainsworth / HXA7241 : 2015-04-25\n\
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
         -c -- check (default)\n\
         -f -- filter\n\
         -r -- replace\n"

   (* execute *)
   else begin

      set_binary_mode_in  stdin  true ;
      set_binary_mode_out stdout true ;
      set_binary_mode_out stderr true ;

      let mode:mode =
         if (Array.length Sys.argv) > 1
         then
            let option1 = Sys.argv.(1) in
            match option1 with
            | "-c" -> Check
            | "-f" -> Filter
            | "-r" -> Replace
            | _    ->
               begin
                  prerr_endline
                     ("*** Failed: unrecognized option: " ^ option1) ;
                  exit 1
               end
         else Check

      and stdinStream = Stream.of_channel stdin in

      try
         match mode with
         | Check   ->
            if Utf8f.checkStream stdinStream
            then prerr_endline "UTF-8 check: OK"
            else (prerr_endline "UTF-8 check: invalid" ; exit 1)
         | Filter  -> Utf8f.filterStream  stdinStream print_string
         | Replace -> Utf8f.replaceStream stdinStream print_string
      with
      | Sys_error s ->
         begin
            prerr_endline ("*** Failed: system IO failure: " ^ s) ;
            exit 1
         end

   end

with
| e -> prerr_string "*** General failure: " ; raise e
