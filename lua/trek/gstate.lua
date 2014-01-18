#!/usr/bin/env lua
--- Luatrek global constants state tables
-- @module trek.gstate
-- @alias M

-- Make module strict by Penlight pl.strict.module()
local strict = require "pl.strict"
local M = strict.module()

--- Luatrek global mutable values and tables
-- Note: all values and tables belongs to the module
-- Some of original numbered arrays are converted into
-- arrays with string keys

-- dimensions of quadrant in sectors
M.NSECTS = 10
-- dimension of galaxy in quadrants
M.NQUADS = 8
-- number of quadrants which are inhabited
-- (#Systemname + 1)
M.NINHAB = 32
-- max number of concurrently pending events
M.MAXEVENTS = 25
-- maximum klingons per quadrant
M.MAXKLQUAD = 9
-- maximum number of starbases in galaxy
M.MAXBASES = 9
-- maximum concurrent distress calls
M.MAXDISTR = 5
-- number of phaser banks
M.NBANKS = 6
-- Names of the star systems (31 entries)
M.Systemname = {
    "Talos IV",
    "Rigel III",
    "Deneb VII",
    "Canopus V",
    "Icarus I",
    "Prometheus II",
    "Omega VII",
    "Elysium I",
    "Scalos IV",
    "Procyon IV",
    "Arachnid I",
    "Argo VIII",
    "Triad III",
    "Echo IV",
    "Nimrod III",
    "Nemisis IV",
    "Centarurus I",
    "Kronos III",
    "Spectros V",
    "Beta III",
    "Gamma Tranguli VI",
    "Pyris III",
    "Triachus",
    "Marcus XII",
    "Kaland",
    "Ardana",
    "Stratos",
    "Eden",
    "Arrikis",
    "Epsilon Eridani IV",
    "Exo III",
}
-- Device token, name, assigned person
M.Device = {
    -- warp engines
    ["WARP"] = { name = "warp drive", person = "Scotty" },
    -- short range scanners
    ["SRSCAN"] = { name = "S.R. scanners", person ="Scotty" },
    -- long range scanners
    ["LRSCAN"] = { name = "L.R. scanners", person = "Scotty" },
    -- phaser control
    ["PHASER"] = { name = "phasers", person = "Sulu" },
    -- photon torpedo control
    ["TORPED"] = { name = "photon tubes", person = "Sulu" },
    -- impulse engines
    ["IMPULSE"] = { name = "impulse engines", person = "Scotty" },
    -- shield control
    ["SHIELD"] = { name = "shield control", person = "Sulu" },
    -- on board computer
    ["COMPUTER"] = { name = "computer", person = "Spock" },
    -- subspace radio
    ["SSRADIO"] = { name = "subspace radio", person = "Uhura" },
    -- life support systems
    ["LIFESUP"] = { name = "life support", person = "Scotty" },
    -- Space Inertial Navigation System
    ["SINS"] = { name = "navigation system", person = "Chekov" },
    -- cloaking device
    ["CLOAK"] = { name = "cloaking device", person = "Scotty" },
    -- transporter
    ["XPORTER"] = { name = "transporter", person = "Scotty" },
    -- shuttlecraft
    ["SHUTTLE"] = { name = "shuttlecraft", person = "Scotty" },
}
-- You lose codes and messages
M.Losemsg = {
    -- ran out of time
    ["L_NOTIME"] = "You ran out of time",
    -- ran out of energy
    ["L_NOENGY"] = "You ran out of energy",
    -- destroyed by a Klingon
    ["L_DSTRYD"] = "You have been destroyed",
    -- ran into the negative energy barrier
    ["L_NEGENB"] = "You ran into the negative energy barrier",
    -- destroyed in a nova
    ["L_SUICID"] = "You destroyed yourself by nova'ing that star",
    -- destroyed in a supernova
    ["L_SNOVA"] = "You have been caught in a supernova",
    -- life support died (so did you)
    ["L_NOLIFE"] = "You just suffocated in outer space",
    -- you could not be rematerialized
    ["L_NOHELP"] = "You could not be rematerialized",
    -- pretty stupid going at warp 10
    ["L_TOOFAST"] = "*** Ship's hull has imploded ***",
    -- ran into a star
    ["L_STAR"] = "You have burned up in a star",
    -- self destructed
    ["L_DSTRCT"] = "Well, you destroyed yourself, but it didn't do any good",
    -- captured by Klingons
    ["L_CAPTURED"] = "You have been captured by Klingons and mercilessly tortured",
    -- you ran out of crew
    ["L_NOCREW"] = "Your last crew member died",
}
-- Klingon move indices
M.KM_OB = 0 -- Old quadrant, Before attack
M.KM_OA = 1 -- Old quadrant, After attack
M.KM_EB = 2 -- Enter quadrant, Before attack
M.KM_EA = 3 -- Enter quadrant, After attack
M.KM_LB = 4 -- Leave quadrant, Before attack
M.KM_LA = 5 -- Leave quadrant, After attack
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
M.Quad = pl.array2d.new(M.NQUADS, M.NQUADS,
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
M.Sect = pl.array2d.new(M.NSECTS, M.NSECTS, nil)

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
