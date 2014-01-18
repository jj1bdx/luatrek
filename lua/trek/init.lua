#!/usr/bin/env lua
--- Luatrek initialization
-- @module trek
-- @alias M

--- globally-required modules
-- Make module strict by Penlight pl.strict.module()
local strict = require "pl.strict"
local M = strict.module()
-- Penlight module table (in global namespace)
pl = require "pl.import_into"()
-- load all submodules
M.getpar = require "trek.getpar"
M.gstate = require "trek.gstate"

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
