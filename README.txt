
UTF-8 Filter
======================================================================


Harrison Ainsworth / HXA7241 : 2012-2014  
http://www.hxa.name/tools

2014-05-18  
2013-01-18  
2012-07-12




Contents
--------

* Description
* Changes
* Metadata



Description
-----------

A small command-line tool to read stdin and check, filter, or replace its valid
UTF-8 content.

* Check: returns status 0 if OK, else (invalid) returns status 1 and
  writes to stderr a message.
* Filter: writes to stdout only the valid UTF-8 content.
* Replace: writes to stdout the content with invalid parts replaced
  with 'replacement' chars (U+FFFD EFBFBD).

(Invalid meaning: malformed, overlong, surrogate, non-char, out-of-range --
according to RFC-3629 and Unicode 6.1.)

Usage:
  utf8check.ml [-(c|f|r)] < inFile [> outFile]
* -c -- check (default)
* -f -- filter
* -r -- replace

Languages:
* OCaml 4.00 -- version 2
* Lua 5.1 / 5.2 -- version 1 (filter-mode only)



Changes
-------

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
   title:`UTF-8 Filter`
   creator:`Harrison Ainsworth`

   date:`2014-05-18`
   date:`2013-01-18`
   date:`2012-07-12`

   description:`A small command-line tool to read stdin and check, filter, or replace its valid UTF-8 content.`
   subject:`Unicode, UTF-8, text, plain-text, command-line`

   type:`software`
   language:`en-GB`
   language:`OCaml 4.00`
   language:`Lua 5.1 / 5.2`
   format:`text/ocaml-4`
   format:`text/lua-5.1`

   relation:`http://www.hxa.name`
   identifier:`http://www.hxa.name/tools/#utf8filter`
   rights:`Creative Commons CC0 1.0 Universal License`
`
