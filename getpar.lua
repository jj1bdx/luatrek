#!/usr/bin/env lua
--- Get parameters
-- @module getpar
-- @alias M

local M = {}

--- get string parameter
-- @param first prompt string (if not string, converted to string)
-- @return first entered string
function M.getstring (prompt)
    io.write(tostring(prompt))
    io.write(": ")
    io.flush()
    return io.read("*l")
end

--- get string parameter
-- See <http://lua-users.org/wiki/SplitJoin>
-- @param first prompt string (if not string, converted to string)
-- @return first number of words in integer
-- @return second table of words
function M.getwords (prompt)
    local s = ""
    local n = 0
    local t = {}
    s = M.getstring(prompt)
    for i in string.gmatch(s, "%S+") do
        table.insert(t, i)
        n = n + 1
    end
    return n, t
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
