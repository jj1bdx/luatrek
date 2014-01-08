#!/usr/bin/env lua
--- Get parameters
-- @module getpar
-- @alias M

local M = {}

--- get string parameter
-- @param first prompt string (if not string, converted to string)
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

--- get parameter splitted as space-separated words into a table 
-- See <http://lua-users.org/wiki/SplitJoin>
-- @param first prompt string (if not string, converted to string)
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

--- get Yes/No boolean parameter
-- Repeat until 
--     Yes (== "Yes" or "yes") (returns true) or
--     No (== "No" or "no") (returns false)
-- is entered
-- @param first prompt string (if not string, converted to string)
-- @return boolean true if yes, false if no
function M.getynpar (prompt)
    while true do
        local s = M.getstring(prompt)
        if ((s == "yes") or (s == "Yes")) then
            return true
        elseif ((s == "no") or (s == "No")) then
            return false
        end
        io.write("invalid input; please enter yes or no\n")
    end
    -- NOTREACHED
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
