#!/usr/bin/env lua
--- Luatrek setup and global constants/variables
-- @module trek
-- @alias M

local M = {}

--- globally-required modules
-- load all submodules

M.const = require "trek.const"
M.getpar = require "trek.getpar"
M.utils = require "trek.utils"

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
