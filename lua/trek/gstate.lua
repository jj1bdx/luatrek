#!/usr/bin/env lua
--- Luatrek global constants state tables
-- @module trek.gstate
-- @alias M

-- Luatrek license statement
--[[
Luatrek ("this software") is covered under the BSD 3-clause license.

This product includes software developed by the University of California, Berkeley
and its contributors.

Copyright (c) 2013, 2014 Kenji Rikitake. All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
  list of conditions and the following disclaimer in the documentation and/or
  other materials provided with the distribution.

* Neither the name of Kenji Rikitake, k2r.org, nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

This software incorporates portions of the BSD Star Trek source code,
distributed under the following license:

Copyright (c) 1980, 1993
     The Regents of the University of California.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. All advertising materials mentioning features or use of this software
   must display the following acknowledgement:
     This product includes software developed by the University of
     California, Berkeley and its contributors.
4. Neither the name of the University nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

[End of LICENSE]
]]

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
-- (Note: listed field names are actually table keys in strings)
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
-- (Note: listed field names are actually table keys in strings)
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
M.KM_NUMBER = 6
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
-- (Note: all codes (table keys) are strings)
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

--- Event codes (represented in string)
-- @table Event_codes
-- @field E_LRTB  long range tractor beam
-- @field E_KATSB Klingon attacks starbase
-- @field E_KDESB Klingon destroys starbase
-- @field E_ISSUE distress call is issued
-- @field E_ENSLV Klingons enslave a quadrant
-- @field E_REPRO a Klingon is reproduced
-- @field E_FIXDV fix a device
-- @field E_ATTACK Klingon attack during rest period
-- @field E_SNAP take a snapshot for time warp
-- @field E_SNOVA supernova occurs

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

--- Starship status
-- @table Ship
-- @field warp Warp factor
-- @field warp2 Warp factor squared
-- @field warp3 Warp factor cubed
-- @field shldup boolean - true if shield is up, false if down
-- @field cloaked boolean - true if cloaking device is on
-- @field energy Starship's energy
-- @field shield Energy in shields
-- @field reserves Life support reserves
-- @field crew Number of crew
-- @field brigfree space left in brig
-- @field torped Number of photon torpedoes
-- @field cloakgood boolean - true if we have moved
-- @field quadx Quadrant X coordinate
-- @field quady Quadrant Y coordinate
-- @field sectx Sector X coordinate
-- @field secty Sector y coordinate
-- @field cond Condition code (in string)
-- @field sinsbad boolean - true if Space Inertial Navigation System is working but not calibrated
-- @field shipname Name of current starship (in string)
-- @field ship Current starship (in Sector Map Code string)
-- @field distressed Number of distress calls
M.Ship = {
    warp = 0,
    warp2 = 0,
    warp3 = 0,
    shldup = false,
    cloaked = false,
    energy = 0,
    shield = 0,
    reserves = 0,
    crew = 0,
    brigfree = 0,
    torped = 0,
    cloakgood = false,
    quadx = 0,
    quady = 0,
    sectx = 0,
    secty = 0,
    cond = "",
    sinsbad = false,
    shipname = "",
    ship = "",
    distressed = 0,
}

--- Game related information, mostly scoring
-- @table Game
-- @field killk Number of Klingons killed
-- @field deaths Number of deaths onboard Enterprise
-- @field negenbar Number of hits on negative energy barrier
-- @field killb Number of starbases killed
-- @field kills Number of stars killed
-- @field skill Skill rating of the player
-- @field length Length of game
-- @field killed boolean - true if you were killed
-- @field killinhab Number of inhabitated starsystems killed
-- @field tourn boolean - true if a tournament game
-- @field passwd Game password string
-- @field snap boolean - true if snapshot taken
-- @field helps Number of help calls
-- @field captives Total number of captives taken
M.Game = {
    killk = 0,
    deaths = 0,
    negenbar = 0,
    killb = 0,
    kills = 0,
    skill = 0,
    length = 0,
    killed = false,
    killinhab = 0,
    tourn = false,
    passwd = "",
    snap = false,
    helps = 0,
    captives = 0,
}

--- Per move information
-- @table Move
-- @field free boolean - true if a move is free (without inducing attacks)
-- @field endgame Game status: 1 if won, 0 if ongoing, -1 if lost
-- @field shldchg boolean - true if shields changed this move
-- @field newquad 2 if just entered this quadrant, 1 after the initquad, 0 if staying in the quadrant for more than a turn
-- @field resting boolean - true if this move is a rest
-- @field time Time used in this move
M.Move = {
    free = false,
    endgame = 0,
    shldchg = false,
    newquad = 0,
    resting = false,
    time = 0,
}

--- Parametric information
-- @table Param
-- @field bases Number of starbases
-- @field klings Number of Klingons
-- @field date Stardate
-- @field time Time left
-- @field resource Federation resources
-- @field energy Starship's energy
-- @field shield Energy in shields
-- @field reserves Life support reserves
-- @field crew Number of crew
-- @field brigfree space left in brig
-- @field torped Number of photon torpedoes
-- @field damfac Table of damage factor (in device names)
-- @field dockfac Docked repair time factor
-- @field regenfac Regeneration factor
-- @field stopengy Energy to do emergency stop
-- @field shupengy Energy to put up sheilds
-- @field klingpwr Klingon initial power
-- @field warptime Time chewer multiplier
-- @field phasfac Klingon phaser power eater factor
-- @field moveprob Table of Probability that a Klingon moves (in Klingon Move Indices)
-- @field movefac Table of Klingon move distance multiplier (in Klingon Move Indices)
-- @field eventdly Table of event time multipliers
-- @field navigcrud Table of navigation crudup factor (of 2 elements)
-- @field cloakenergy Cloaking device energy per stardate
-- @field damprob Table of damage probability (in device names) (sum of damage probabilities must add to 1000)
-- @field hitfac Klingon attack factor
-- @field klingcrew Number of Klingons in a crew
-- @field srndrprob Surrender probability
-- @field energylow Low energy mark to declare Condition YELLOW
M.Param = {
    bases = 0,
    klings = 0,
    date = 0,
    time = 0,
    resource = 0,
    energy = 0,
    shield = 0,
    reserves = 0,
    crew = 0,
    brigfree = 0,
    torped = 0,
    damfac = {
        ["WARP"] = 0,
        ["SRSCAN"] = 0,
        ["LRSCAN"] = 0,
        ["PHASER"] = 0,
        ["TORPED"] = 0,
        ["IMPULSE"] = 0,
        ["SHIELD"] = 0,
        ["COMPUTER"] = 0,
        ["SSRADIO"] = 0,
        ["LIFESUP"] = 0,
        ["SINS"] = 0,
        ["CLOAK"] = 0,
        ["XPORTER"] = 0,
    },
    dockfac = 0,
    regenfac = 0,
    stopengy = 0,
    shupengy = 0,
    klingpwr = 0,
    warptime = 0,
    phasfac = 0,
    moveprob = pl.tablex.new(M.KM_NUMBER, 0),
    movefac = pl.tablex.new(M.KM_NUMBER, 0),
    eventdly = {
        ["E_LRTB"] = 0,
        ["E_KATSB"] = 0,
        ["E_KDESB"] = 0,
        ["E_ISSUE"] = 0,
        ["E_ENSLV"] = 0,
        ["E_REPRO"] = 0,
        ["E_FIXDV"] = 0,
        ["E_ATTACK"] = 0,
        ["E_SNAP"] = 0,
        ["E_SNOVA"] = 0,
    },
    navigcrud = pl.tablex.new(2, 0),
    cloakenergy = 0,
    damprob = {
        ["WARP"] = 0,
        ["SRSCAN"] = 0,
        ["LRSCAN"] = 0,
        ["PHASER"] = 0,
        ["TORPED"] = 0,
        ["IMPULSE"] = 0,
        ["SHIELD"] = 0,
        ["COMPUTER"] = 0,
        ["SSRADIO"] = 0,
        ["LIFESUP"] = 0,
        ["SINS"] = 0,
        ["CLOAK"] = 0,
        ["XPORTER"] = 0,
    },
    hitfac = 0,
    klingcrew = 0,
    srndrprob = 0,
    energylow = 0,
}

--- Other information kept in a snapshot
-- @table Now
-- @field bases Number of starbases
-- @field klings Number of klingons
-- @field date Stardate
-- @field time Time Left
-- @field resource Federation resources
-- @field distressed Number of currently distressed quadrants
-- @field eventptr Pointer (or a copy) to a event table
-- @field base Table of locations of starbases (in {x, y} coordinates)
M.Now = {
    bases = 0,
    klings = 0,
    date = 0,
    time = 0,
    resource = 0,
    distressed = 0,
    eventptr = {}, -- @todo what to do with this type?
    base = pl.tablex.new(M.MAXBASES, {x = 0, y = 0}),
}

--- Other stuff, which is not dumped in a shapshot
-- @table Etc
-- @field kling Table of sorted Klingon list
-- @field nkling Number of Klingons in this sector (<0 means automatic override mode)
-- @field starbase Table of starbase coordinates in current quadrant (in {x, y})
-- @field snapshot Snapshot for time warp
-- @field statreport boolean - true to get a status report on a short range scan
M.Etc = {
    kling = pl.tablex.new(M.MAXKLQUAD,
        {
--- Klingon list
-- @table kling
-- @field x X coordinate
-- @field y Y coordinate
-- @field power Power left
-- @field dist Distance to Enterprise
-- @field avgdist Average of distance over this move
-- @field srndreq boolean - true if surrender has been requested
            x = 0,
            y = 0,
            power = 0,
            dist = 0,
            avgdist = 0,
            srndreq = false,
        }
    ),
    nkling = 0,
    starbase = {
        x = 0, 
        y = 0,
    },
    snapshot = {}, -- @todo what should be in this variable?
    statreport = false,
}

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
