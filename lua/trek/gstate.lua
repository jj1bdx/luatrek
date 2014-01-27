#!/usr/bin/env lua
--- Luatrek global constants state tables
-- @module trek.gstate
-- @alias M

--- Make module strict by Penlight pl.strict.module()
local strict = require "pl.strict"
local M = strict.module()

--- Luatrek global mutable values and tables
-- Note: all values and tables belongs to the module namespace
-- Some of original numbered arrays are converted into
-- arrays with string keys

--- dimensions of quadrant in sectors
M.NSECTS = 10

--- dimension of galaxy in quadrants
M.NQUADS = 8

--- number of quadrants which are inhabited
-- (#Systemname + 1)
M.NINHAB = 32

--- max number of concurrently pending events
M.MAXEVENTS = 25

--- maximum klingons per quadrant
M.MAXKLQUAD = 9

--- maximum number of starbases in galaxy
M.MAXBASES = 9

--- maximum concurrent distress calls
M.MAXDISTR = 5

--- number of phaser banks
M.NBANKS = 6

--- Names of the star systems (31 entries)
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

--- Device token, name, assigned person
-- (Note: field names are strings)
-- @table Device
-- @field WARP Warp engines
-- @field SRSCAN Short range scanners
-- @field LRSCAN Long range scanners
-- @field PHASER Phaser control
-- @field TORPED Photon torpedo control
-- @field IMPULSE Impulse engines
-- @field SHIELD Shield control
-- @field COMPUTER On board computer
-- @field SSRADIO Subspace radio
-- @field LIFESUP Life support systems
-- @field SINS Space Inertial Navigation System
-- @field CLOAK Cloaking device
-- @field XPORTER Transporter
-- @field SHUTTLE Shuttlecraft
M.Device = {
    ["WARP"] = { name = "warp drive", person = "Scotty" },
    ["SRSCAN"] = { name = "S.R. scanners", person ="Scotty" }, 
    ["LRSCAN"] = { name = "L.R. scanners", person = "Scotty" }, 
    ["PHASER"] = { name = "phasers", person = "Sulu" }, 
    ["TORPED"] = { name = "photon tubes", person = "Sulu" }, 
    ["IMPULSE"] = { name = "impulse engines", person = "Scotty" }, 
    ["SHIELD"] = { name = "shield control", person = "Sulu" }, 
    ["COMPUTER"] = { name = "computer", person = "Spock" }, 
    ["SSRADIO"] = { name = "subspace radio", person = "Uhura" }, 
    ["LIFESUP"] = { name = "life support", person = "Scotty" }, 
    ["SINS"] = { name = "navigation system", person = "Chekov" }, 
    ["CLOAK"] = { name = "cloaking device", person = "Scotty" }, 
    ["XPORTER"] = { name = "transporter", person = "Scotty" }, 
    ["SHUTTLE"] = { name = "shuttlecraft", person = "Scotty" }, 
}

--- You lose codes and messages 
-- (Note: field names are strings)
-- @table Losemsg
-- @field L_NOTIME Ran out of time
-- @field L_NOENGY Ran out of energy
-- @field L_DSTRYD Destroyed by a Klingon
-- @field L_NEGENB Ran into the negative energy barrier
-- @field L_SUICID Destroyed in a nova
-- @field L_SNOVA Destroyed in a supernova
-- @field L_NOLIFE Life support died (so did you)
-- @field L_NOHELP You could not be rematerialized
-- @field L_TOOFAST Pretty stupid going at warp 10
-- @field L_STAR Ran into a star
-- @field L_DSTRCT Self destructed
-- @field L_CAPTURED Captured by Klingons
-- @field L_NOCREW You ran out of crew
M.Losemsg = {
    ["L_NOTIME"] = "You ran out of time", 
    ["L_NOENGY"] = "You ran out of energy", 
    ["L_DSTRYD"] = "You have been destroyed", 
    ["L_NEGENB"] = "You ran into the negative energy barrier", 
    ["L_SUICID"] = "You destroyed yourself by nova'ing that star", 
    ["L_SNOVA"] = "You have been caught in a supernova", 
    ["L_NOLIFE"] = "You just suffocated in outer space", 
    ["L_NOHELP"] = "You could not be rematerialized", 
    ["L_TOOFAST"] = "*** Ship's hull has imploded ***", 
    ["L_STAR"] = "You have burned up in a star", 
    ["L_DSTRCT"] = "Well, you destroyed yourself, but it didn't do any good", 
    ["L_CAPTURED"] = "You have been captured by Klingons and mercilessly tortured", 
    ["L_NOCREW"] = "Your last crew member died", 
}

--- Klingon move indices
-- @todo this should be symbolic
M.KM_OB = 0 -- Old quadrant, Before attack
M.KM_OA = 1 -- Old quadrant, After attack
M.KM_EB = 2 -- Enter quadrant, Before attack
M.KM_EA = 3 -- Enter quadrant, After attack
M.KM_LB = 4 -- Leave quadrant, Before attack
M.KM_LA = 5 -- Leave quadrant, After attack

--- Two dimensional table of the Quadrants
-- @table Quad
-- @field bases Number of bases in this quadrant
-- @field klings Number of Klingons in this quadrant
-- @field holes Number of black holes in this quadrant
-- @field scanned Star chart entry code
--  (0 - 999: taken as is, -1: not yet scanned ("..."),
--   1000: supernova ("///"), 1001: starbase + unknown (".1."))
-- @field stars Number of stars in this quadrant
-- @field systemname Starsystem name code
--  (>= 1: index into Systemname table for live system,
--   0: dead or nonexistent starsystem)
-- @field distressed Distressed starsystem
--  (>= 1: the index into the Event table which will have the system name,
--   0: not distressed)
M.Quad = pl.array2d.new(M.NQUADS, M.NQUADS,
    { 
        bases = 0, 
        klings = 0,
        holes = 0,
        scanned = -1,
        starts = 0,
        systemname = 0,
        distressed = 0,
    }
)

--- Sector Map Code table for the short range sensor display
-- (Note: all codes (field names) are strings)
-- @table Sectdisp
-- @field EMPTY Empty space
-- @field STAR Star
-- @field BASE Starbase
-- @field ENTERPRISE USS Enterprise
-- @field QUEENE USS Queene
-- @field KLINGON Klingon ship
-- @field INHABIT Inhabited star
-- @field HOLE Blackhole
M.Sectdisp = {
    ["EMPTY"] = ".",
    ["STAR"] = "*",
    ["BASE"] = "#",
    ["ENTERPRISE"] = "E",
    ["QUEENE"] = "Q",
    ["KLINGON"] = "K",
    ["INHABIT"] = "@",
    ["HOLE"] = " ", -- @todo Isn't this hard to recognize? 
}

--- Two dimensional table of the Sectors
-- @table Sect
M.Sect = pl.array2d.new(M.NSECTS, M.NSECTS, nil)

-- Event codes (represented in string)
--   E_LRTB   /* long range tractor beam */
--   E_KATSB  /* Klingon attacks starbase */
--   E_KDESB  /* Klingon destroys starbase */
--   E_ISSUE  /* distress call is issued */
--   E_ENSLV  /* Klingons enslave a quadrant */
--   E_REPRO  /* a Klingon is reproduced */
--   E_FIXDV  /* fix a device */
--   E_ATTACK /* Klingon attack during rest period */
--   E_SNAP   /* take a snapshot for time warp */
--   E_SNOVA  /* supernova occurs */

--- Event table (of the table with the following field names)
-- @table Event
-- @field x Coordinate X
-- @field y Coordinate Y
-- @field date Trap date
-- @field evcode Event code ("": unallocated)
-- @field systemname Index into Systemname table for reported distress calls
-- @field hidden boolean - true if unreported (SSradio out)
-- @field ghost boolean - true if actually already expired
M.Event = pl.tablex.new(M.MAXEVENTS,
    {
        x = 0,
        y = 0,
        date = 0,
        evcode = "",
        systemname = 0, 
        hidden = false,
        ghost = false, 
    }
)

--- Game length table (to be migrated to setup module)
-- @table Lentab
-- @field s -> short
-- @field short Short game
-- @field m -> medium
-- @field medium Medium game
-- @field l -> long
-- @field long Long game
-- @field restart For restarting the game (Note: in bsdtrek it's NULL but the code compares NULL to 0 and that is BAD)
M.Lentab = {
    ["s"] = 1, ["short"] = 1,
    ["m"] = 2, ["medium"] = 2,
    ["l"] = 4, ["long"] = 4,
    ["restart"] = -1, 
}

--- Game skill table (to be migrated to setup module)
-- @table Skitab
-- @field n -> novice
-- @field novice Novice
-- @field f -> fair
-- @field fair Fair
-- @field g -> good
-- @field good Good
-- @field e -> expert
-- @field expert Expert
-- @field c -> commodore
-- @field commodore Commodore
-- @field i -> impossible
-- @field impossible Impossible
M.Skitab = {
    ["n"] = 1, ["novice"] = 1,
    ["f"] = 2, ["fair"] = 2,
    ["g"] = 3, ["good"] = 3,
    ["e"] = 4, ["expert"] = 4,
    ["c"] = 5, ["commodore"] = 5,
    ["i"] = 6, ["impossible"] = 6,
}

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
