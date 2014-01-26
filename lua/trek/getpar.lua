#!/usr/bin/env lua
--- Get parameters
-- @module trek.getpar
-- @alias M

-- Make module strict by Penlight pl.strict.module()
local strict = require "pl.strict"
local M = strict.module()

--- Get string parameter
-- @param prompt string (if not string, converted to string)
-- @return first entered string (if no string entered, "")
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
-- See <http://lua-users.org/wiki/SplitJoin>
-- @param prompt string (if not string, converted to string)
-- @return first number of words in integer
-- @return second table of words
function M.getwords (prompt)
    local t = {}
    local s = M.getstring(prompt)
    for i in string.gmatch(s, "%S+") do
        table.insert(t, i)
    end
    return #t, t
end

--- Get Yes/No boolean parameter
-- Repeat until 
--     Yes (== "Yes" or "yes") (returns true) or
--     No (== "No" or "no") (returns false)
-- is entered
-- @param prompt string (if not string, converted to string)
-- @return boolean true if yes, false if no
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
-- Find the command word in the given table
-- If the command word is "?" then the list of
-- available input is printed, sorted by the key
-- @param command string
-- @param wordtab table of valid command words
-- @return first matched table value if existed, nil if failed

function M.checkcmd (command, wordtab)
    if command == "?" then -- write help and return nil
        local c = 4
        for k, v in pl.tablex.sort(wordtab) do
            pl.utils.printf("%14.14s", k)
            c = c - 1
            if c == 0 then
                io.write("\n")
                c = 4
            else
            io.write(" ")
            end
        end
        if c > 0 then
            io.write("\n")
        end
        return nil
    else -- check command
        local v = wordtab[command]
        if v == nil then
            io.write("Invalid input: ? for valid inputs\n")
        end
        return v
    end
end

--- Get command and parameter
-- get parameter splitted as space-separated words into a table 
-- and find the first word as the command defined in the given table
-- @param prompt string (if not string, converted to string)
-- @param wordtab table of valid command words
-- @return first matched table value if existed, nil if failed
-- @return second number of words in integer
-- @return third table of words
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
