#!/usr/bin/env lua
--- Luatrek initialization
-- @module trek
-- @alias M

local M = {}

--- globally-required modules
-- strict checking on global variables
strict = require "pl.strict"
-- Penlight module table (in global namespace)
pl = require "pl.import_into"()
-- load all submodules
M.const = require "trek.const"
M.getpar = require "trek.getpar"

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
