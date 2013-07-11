#!/usr/bin/env lua
--------------------------------------------------------------------------------
--                                                                            --
--  UTF-8 filter (Lua 5.1 / 5.2)                                              --
--  Harrison Ainsworth / HXA7241 : 2012                                       --
--                                                                            --
--  http://www.hxa.name/tools/                                                --
--                                                                            --
--  License: CC0 -- http://creativecommons.org/publicdomain/zero/1.0/         --
--                                                                            --
--------------------------------------------------------------------------------




--- Read next valid UTF-8 char from open file.
--- (Discards invalid chars until (moving forward) a valid one is found.)
---
--- Invalid meaning: malformed, overlong, surrogate, non-char.
---
--- According to: RFC-3629 -- http://tools.ietf.org/html/rfc3629
--- and: Unicode 6.1 -- http://www.unicode.org/versions/Unicode6.1.0/
---
--- @param fileIn (in(out)) open file to read from
--- @return valid UTF-8 char (string) | nil for EOF | false for fail
---
function readCharUtf8( fileIn )

   local bytes = {}

   -- look for next valid UTF-8 char
   while true do
      -- read string one byte long
      local s = fileIn:read( 1 )

      -- return EOF
      if not s then return nil end

      -- convert to byte, and buffer it
      local b = string.byte( s )
      table.insert( bytes, b )

      -- test for invalidities
      local isMalformed = ((#bytes > 1) and ((b < 0x80) or (b > 0xBF))) or
         ((#bytes == 1) and (((b > 0x7F) and (b < 0xC2)) or (b > 0xF4)))
      local isOverlong = (#bytes == 2) and
         (((bytes[1] == 0xE0) and (bytes[2] < 0xA0)) or
         ((bytes[1] == 0xF0) and (bytes[2] < 0x90)))
      local isSurrogate = (#bytes == 2) and
         ((bytes[1] == 0xED) and (bytes[2] >= 0xA0))
      local isNonchar1a = (#bytes == 3) and
         ((bytes[1] == 0xEF) and (bytes[2] == 0xBF) and (bytes[3] >= 0xBE))
      local isNonchar1b = false
      if #bytes == 4 then
         local p = (math.floor(bytes[2] / 16) % 4) + (bytes[1] % 7) * 4
         isNonchar1b = (p >= 0x01) and (p <= 0x10) and
            (bytes[3] == 0xBF) and (bytes[4] >= 0xBE) and
            ((bytes[2] % 0x10) == 0x0F) and (math.floor(bytes[1] / 16) == 0x0F)
      end
      local isNonchar2 = (#bytes == 3) and
         ((bytes[1] == 0xEF) and (bytes[2] == 0xB7) and
         (bytes[3] >= 0x90) and (bytes[3] <= 0xA7))

      -- invalid
      if isMalformed or isOverlong or isSurrogate or
         isNonchar1a or isNonchar1b or isNonchar2 then

         -- reset read state (return stream failure)
         if (#bytes > 1) and isMalformed and (not fileIn:seek( "cur", -1 )) then
            return false
         end
         bytes = {}

      -- valid
      else
         -- return accumulated char if complete
         if ((#bytes == 1) and (bytes[1] <= 0x7F)) or
            ((#bytes == 2) and (bytes[1] <  0xE0)) or
            ((#bytes == 3) and (bytes[1] <  0xF0)) or
            ( #bytes == 4) then

            return string.char( table.unpack(bytes) )
         end
      end
   end

end




-- run ------------------------------------------------------------------------

-- check if help message needed
if (arg[1] == "-?") or (arg[1] == "--help") then

   -- print help message
   print( "\n" ..
      "  UTF-8 filter (Lua 5.1 / 5.2)\n" ..
      "  Harrison Ainsworth / HXA7241 : 2012-07-12\n" ..
      "  http://www.hxa.name/\n" ..
      "\n" ..
      "Reads stdin, and writes to stdout only the valid UTF-8 content.\n" ..
      "(Invalid meaning: malformed, overlong, surrogate, non-char --\n" ..
      "according to RFC-3629 and Unicode 6.1.)\n" ..
      "\n" ..
      "usage:\n" ..
      "  utf8filter.lua < inFile > outFile\n" )

-- execute
else

   -- make Lua 5.1 look like Lua 5.2
   if not table.unpack then table.unpack = unpack end

   while true do
      local c = readCharUtf8( io.stdin )

      -- exit on EOF or failure
      if not c then return (c == nil) and 0 or 1 end

      io.stdout:write( c )
   end

end








-- notes -----------------------------------------------------------------------

--[[

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

--]]
