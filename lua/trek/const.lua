#!/usr/bin/env lua
--- Luatrek setup and global constants/variables
-- @module trek.const
-- @alias M

local M = {}

--- Read-only table function for immutable constants
-- @params table table to be set as read-only
-- @return first metatable set as read-only
-- @see <http://lua-users.org/wiki/ReadOnlyTables>

function M.readonlytable(table)
    return setmetatable({}, {
        __index = table,
        __newindex = function(table, key, value)
                         error("Attempt to modify read-only table")
                     end,
        __metatable = false
        });
end

--- Luatrek constants
-- Notes:
-- * these are immutable but cannot be iterated
--   (by pairs, ipairs, next, the # operator, etc.)
-- * it is still possible to modify members of members of read-only tables
-- * rawset() and table.insert can still be used to directly modify a read-only table
-- @see <http://lua-users.org/wiki/ReadOnlyTables>

M.Const = M.readonlytable {
    NSECTS = 10,    -- dimensions of quadrant in sectors
    NQUADS = 8,     -- dimension of galaxy in quadrants
    NINHAB = 32,    -- number of quadrants which are inhabited
    MAXEVENTS = 25, -- max number of concurrently pending events
    MAXKLQUAD = 9,  -- maximum klingons per quadrant
    MAXBASES = 9,   -- maximum number of starbases in galaxy
    MAXDISTR = 5,   -- maximum concurrent distress calls
    NBANKS = 6,     -- number of phaser banks
    otherstuff = {} -- endmark
}

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
