#!/usr/bin/env lua
--- Luatrek global state tables
-- @module trek.gstate
-- @alias M

local M = {}

--- Luatrek global mutable values and tables
-- Note: these are global variables

-- Two dimensional table of the Quadrants
-- scanned:
--   0 - 999: taken as is
--   -1:      not yet scanned ("...")
--   1000:    supernova ("///")
--   1001:    starbase + unknown (".1.")
--   
-- systemname: 
--   >= 1: index into Systemname table for live system
--   0:    dead or nonexistent starsystem
-- distressed:
--   >= 1: the index into the Event table which will have the system name
--   0:    not distressed
Quad = pl.array2d.new(NQUADS, NQUADS,
    { bases = 0, -- number of bases in this quadrant
      klings = 0, -- number of Klingons in this quadrant
      holes = 0, -- number of black holes in this quadrant
      scanned = -1, -- star chart entry code
      starts = 0, -- number of stars in this quadrant
      systemname = 0, -- starsystem name code
      distressed = 0, -- distressed starsystem
    })

-- Two dimensional table of the Sectors
-- See the sector map codes in trek.const
Sect = pl.array2d.new(NSECTS, NSECTS, nil)

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
