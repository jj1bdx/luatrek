#!/usr/bin/env lua
--- Luatrek miscellaneous utility functions
-- @module utils
-- @alias M

local M = {}

--- Create one-dimensional array
-- (table filled in by a non-function value)
-- @param m number of elements
-- @param x initial value (non-nil)
-- @return first created array
-- @see <http://lua.2524044.n2.nabble.com/Multidimensional-Arrays-td6609098.html>

function M.create1darray (m, x)
    if x == nil then
        error("create1darray: no nil element")
    end
    local a = {}
    for i = 1, m do
        a[i] = x
    end
    return a
end

--- Create two-dimensional array
-- (table filled in by a non-function value)
-- each element: array[row][column]
-- @param n number of rows
-- @param m number of columns
-- @param x initial value (non-nil)
-- @return first created array
-- @see <http://lua.2524044.n2.nabble.com/Multidimensional-Arrays-td6609098.html>

function M.create2darray (n, m, x)
    if x == nil then
        error("create2darray: no nil element")
    end
    local a = {}
    for i = 1, n do
        a[i] = M.create1darray(m, x)
    end
    return a
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
