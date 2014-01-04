#!/usr/bin/env lua
--- Get parameters
-- @module getpar
-- @alias M

local M = {}

--- get string parameter
-- @param first prompt string
-- @return first entered string
function M.getstring (prompt)
    io.write(prompt)
    io.write(": ")
    return io.read("*l")
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
