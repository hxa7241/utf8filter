
UTF-8 Filter tool
======================================================================


Harrison Ainsworth / HXA7241 : 2012-2015  
http://www.hxa.name/tools

2015-05-16  
2014-05-18  
2013-01-18  
2012-07-12




Contents
--------

* Description
* Build
* Changes
* Metadata



Description
-----------

A small command-line tool that: reads stdin and checks, filters, or
replaces it as UTF-8 content.
* Check: returns status 0 if all content valid UTF-8, else status 1.
* Filter: writes to stdout only the valid UTF-8 content.
* Replace: writes to stdout the valid UTF-8 content with invalid
  parts replaced with standard replacement chars (U+FFFD U8+EFBFBD).

(According to RFC-3629 and Unicode 7.0.).

Usage:
  utf8filter[b] [-(c|f|r)] [< inFile] [> outFile]
-c  check (default)  
-f  filter  
-r  replace

Languages:
* OCaml 4.02 (or thereabouts)



Build
-----

Run make, to produce:

executables:
* utf8filter      -- native executable
* utf8filterb     -- bytecode executable

libraries:
* utf8filter.cmi  -- library interface
* utf8filter.cmxa -- native library
* utf8filter.cma  -- bytecode library
* utf8filter.a    -- library object



Changes
-------

### Version 3 : 2015-05-16 ###

(OCaml)

* wholly re-implemented
   * separate library module
   * build native and bytecode


### Version 2 : 2014-05-18 ###

(OCaml)

* Added check and replace modes.
* Added invalid byte count message to filter mode.
* Added general failure message.
* Added out-of-range invalidity check


### Version 1 : 2012-07-12, 2013-01-18 ###

(Lua, OCaml)

* Filter-mode only.



Metadata
--------

DC:`
   title:`UTF-8 Filter tool`
   creator:`Harrison Ainsworth / HXA7241`

   date:`2015-05-16`
   date:`2014-05-18`
   date:`2013-01-18`
   date:`2012-07-12`

   description:`A small command-line tool that: reads stdin and checks, filters, or replaces it as UTF-8 content.`
   subject:`Unicode, UTF-8, text, plain-text, command-line, OCaml`

   type:`software`
   language:`en-GB`
   language:`OCaml 4.02`
   format:`text/ocaml`

   relation:`http://www.hxa.name`
   identifier:`http://www.hxa.name/tools/#utf8filter`
   rights:`Creative Commons CC0 1.0 Universal License`
`
