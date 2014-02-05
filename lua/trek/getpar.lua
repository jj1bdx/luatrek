#!/usr/bin/env lua
--- Functions of obtaining user input parameters
-- @module trek.getpar
-- @alias M

-- Luatrek license statement
--[[
Luatrek ("this software") is covered under the BSD 3-clause license.

This product includes software developed by the University of California, Berkeley
and its contributors.

Copyright (c) 2013, 2014 Kenji Rikitake. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
  list of conditions and the following disclaimer in the documentation and/or
  other materials provided with the distribution.

* Neither the name of Kenji Rikitake, k2r.org, nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

This software incorporates portions of the BSD Star Trek source code,
distributed under the following license:

Copyright (c) 1980, 1993
     The Regents of the University of California.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. All advertising materials mentioning features or use of this software
   must display the following acknowledgement:
     This product includes software developed by the University of
     California, Berkeley and its contributors.
4. Neither the name of the University nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

[End of LICENSE]
]]

-- Make module strict by Penlight pl.strict.module()
local strict = require "pl.strict"
local M = strict.module()

--- Get string parameter
-- @string prompt (if not string, converted to string)
-- @treturn string entered string (if no string entered, "")
function M.getstring (prompt)
    io.write(tostring(prompt))
    io.write(": ")
    io.flush()
    local s = io.read("*l")
    if (type(s) == "string") then
        return s
    else
        return ""
    end
end

--- Get parameter splitted as space-separated words into a table 
-- (see http://lua-users.org/wiki/SplitJoin)
-- @string prompt (if not string, converted to string)
-- @treturn int number of words in integer
-- @treturn tab table of words
function M.getwords (prompt)
    local t = {}
    local s = M.getstring(prompt)
    for i in string.gmatch(s, "%S+") do
        table.insert(t, i)
    end
    return #t, t
end

--- Get Yes/No boolean parameter
-- repeating until Yes (returns true) or No (returns false) is entered
-- @string prompt (if not string, converted to string)
-- @treturn bool true if yes, false if no
function M.getynpar (prompt)
    while true do
        local s = M.getstring(prompt)
        if ((s == "yes") or (s == "Yes") or
            (s == "y") or (s == "Y")) then
            return true
        elseif ((s == "no") or (s == "No") or
                (s == "n") or (s == "N")) then
            return false
        end
        io.write("invalid input; please enter yes or no\n")
    end
    -- NOTREACHED
end

--- Get string parameter
-- repeating until non-null string is entered
-- @string prompt (if not string, converted to string)
-- @treturn string result of input
function M.getstrpar (prompt)
    while true do
        local s = M.getstring(prompt)
        if string.len(s) > 0 then
            return s
        end
    end
    -- NOTREACHED
end

--- Check command word
-- by finding the command word in the given table 
-- and return the word when found;
-- if the command word is "?", then the list of
-- available input is printed, sorted by the key
-- @string command command string
-- @tab wordtab table of valid command words
-- @return first matched table value if existed, nil if failed

function M.checkcmd (command, wordtab)
    if command == "?" then -- write help and return nil
        -- four words per line, separated by comma
        local c = 4
        local punct = false
        for k, v in pl.tablex.sort(wordtab) do
            if punct then
                io.write(", ")
                punct = false
            end
            io.write(k)
            c = c - 1
            if c == 0 then
                io.write(",\n")
                c = 4
                punct = false
            else
                punct = true
            end
        end
        if c > 0 then
            io.write("\n")
        end
        return nil
    else -- check command and return the matched result
        local v = wordtab[command]
        if v == nil then
            io.write("Invalid input: ? for valid inputs\n")
        end
        return v
    end
end

--- Get command and parameters
-- which are splitted as space-separated words into a table 
-- and set the first word as the command defined in the given table
-- @string prompt string (if not string, converted to string)
-- @string wordtab table of valid command words
-- @return first matched table value if existed, nil if failed
-- @treturn int number of words in integer
-- @treturn tab table of words
function M.getcodpar (prompt, wordtab)
    local num, t, val
    repeat
        num, t = M.getwords(prompt)
        val = M.checkcmd(t[1], wordtab)
    until val -- not nil
    return val, num, t
end


-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
