#!/usr/bin/env lua
--- Luatrek global constants
-- @module trek.const
-- @alias M

local M = {}

--- Luatrek constant values and tables
-- Note: these are global variables
-- Some of original numbered arrays are converted into
-- arrays with string keys
-- Note: tables representing bsdtrek C structures
-- are defined in trek.gstate as *global* variables

-- dimensions of quadrant in sectors
NSECTS = 10
-- dimension of galaxy in quadrants
NQUADS = 8
-- number of quadrants which are inhabited
-- (#Systemname + 1)
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
-- Names of the star systems (31 entries)
Systemname = {
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
Device = {
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
Losemsg = {
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
KM_OB = 0 -- Old quadrant, Before attack
KM_OA = 1 -- Old quadrant, After attack
KM_EB = 2 -- Enter quadrant, Before attack
KM_EA = 3 -- Enter quadrant, After attack
KM_LB = 4 -- Leave quadrant, Before attack
KM_LA = 5 -- Leave quadrant, After attack
-- Sector map codes
EMPTY      = '.'
STAR       = '*'
BASE       = '#'
ENTERPRISE = 'E'
QUEENE     = 'Q'
KLINGON    = 'K'
INHABIT    = '@'
HOLE       = ' '

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
