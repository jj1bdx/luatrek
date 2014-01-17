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

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
