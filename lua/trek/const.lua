#!/usr/bin/env lua
--- Luatrek setup and global constants/variables
-- @module trek.const
-- @alias M

local M = {}

--- Luatrek constants
-- Note: these are global variables

-- dimensions of quadrant in sectors
NSECTS = 10
-- dimension of galaxy in quadrants
NQUADS = 8
-- number of quadrants which are inhabited
NINHAB = 32
-- max number of concurrently pending events
MAXEVENTS = 25
-- maximum klingons per quadrant
MAXKLQUAD = 9
-- maximum number of starbases in galaxy
MAXBASES = 9
-- maximum concurrent distress calls
MAXDISTR = 5
-- number of phaser banks
NBANKS = 6

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
