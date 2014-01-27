#!/usr/bin/env lua
--- Functions of obtaining user input parameters
-- @module trek.getpar
-- @alias M

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
