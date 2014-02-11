#!/usr/bin/env lua
--- Setup function
-- @module trek.setup
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
--- Shorthand for trek.gstate prefix
local V = require "trek.gstate"
--- Global Game table
local Game = V.Game
--- Global Param table
local Param = V.Param
--- Global Ship table
local Ship = V.Ship
--- Global Now table
local Now = V.Now
--- Global Event table
local Event = V.Event
--- Global Quad table
local Quad = V.Quad
--- Global Sect table
local Sect = V.Sect
--- Global Move table
local Move = V.Sect

--- Game length table
-- @table Lentab
-- @field s -> short
-- @field short Short game
-- @field m -> medium
-- @field medium Medium game
-- @field l -> long
-- @field long Long game
-- @field restart For restarting the game (Note: in bsdtrek it's NULL but the code compares NULL to 0 and that is BAD)
local Lentab = {
    ["s"] = 1, ["short"] = 1,
    ["m"] = 2, ["medium"] = 2,
    ["l"] = 4, ["long"] = 4,
    ["restart"] = -1,
}

--- Game skill table
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
local Skitab = {
    ["n"] = 1, ["novice"] = 1,
    ["f"] = 2, ["fair"] = 2,
    ["g"] = 3, ["good"] = 3,
    ["e"] = 4, ["expert"] = 4,
    ["c"] = 5, ["commodore"] = 5,
    ["i"] = 6, ["impossible"] = 6,
}

--- Setup Luatrek global variables
function M.setup ()
    local r = 0
    while r == 0 do
        r = trek.getpar.getcodpar("What length game", Lentab)
        if r < 0 then
            if trek.dumpgame.restartgame() then
                -- state loading successful, no more setup
                return
            end
        end
    end -- loop breaks when r > 0
    Game.length = r
    Game.skill = trek.getpar.getcodpar("What skill game", Skitab)
    Game.tourn = false
    Game.passwd = trek.getpar.getstrpar("Enter a password")
    local seed = 0
    if Game.passwd == "tournament" then
        Game.passwd = trek.getpar.getstrpar("Enter tournament code")
        Game.tourn = true
        for c in Game.passwd:gmatch"." do
            seed = bit32.lrotate(bit32.bxor(seed, c:byte()), 1)
        end
    else
        seed = os.time()
    end
    math.randomseed(seed)
    if Game.skill == 6 then
        Param.bases = 1
    else
        Param.bases = math.random(2, (7 - Game.skill))
    end
    Now.bases = Param.bases
    Param.time = 6 * Game.length + 2
    Now.time = Param.time
    -- @warning On the bsdtrek the max value is 127 but not here
    Param.klings = math.floor(Game.skill * Game.length * 
                    (5.0 + (math.random() * 1.125)))
    Now.klings = Param.klings
    Param.energy = 5000
    Ship.energy = Param.energy
    Param.torped = 10
    Ship.torped = Param.torped
    Ship.ship = "ENTERPRISE"
    Ship.shipname = "Enterprise"
    Param.shield = 1500
    Ship.shield = Param.shield
    Param.resource = Param.klings * Param.time
    Now.resource = Param.resource
    Param.reserves = (6 - Game.skill) * 2
    Ship.reserves = Param.reserves
    Param.crew = 387
    Ship.crew = Param.crew
    Param.brigfree = 400
    Ship.brigfree = Param.brigfree
    Ship.shldup = true
    Ship.cond = "GREEN"
    Ship.warp = 5.0
    Ship.warp2 = 25.0
    Ship.warp3 = 125.0
    Ship.sinsbad = false
    Ship.cloaked = false
    Param.date = math.random(20, 39) * 100;
    Now.date = Param.date
    for k, v in pairs(Param.damfac) do
        Param.damfac[k] = math.log(Game.skill + 0.5)
    end
    -- these probabilities must sum to 1000
    Param.damprob["WARP"] = 70     -- warp drive            7.0%
    Param.damprob["SRSCAN"] = 110  -- short range scanners 11.0%
    Param.damprob["LRSCAN"] = 110  -- long range scanners  11.0%
    Param.damprob["PHASER"] = 125  -- phasers              12.5%
    Param.damprob["TORPED"] = 125  -- photon torpedoes     12.5%
    Param.damprob["IMPULSE"] = 75  -- impulse engines       7.5%
    Param.damprob["SHIELD"] = 150  -- shield control       15.0%
    Param.damprob["COMPUTER"] = 20 -- computer              2.0%
    Param.damprob["SSRADIO"] = 35  -- subspace radio        3.5%
    Param.damprob["LIFESUP"] = 30  -- life support          3.0%
    Param.damprob["SINS"] = 20     -- navigation system     2.0%
    Param.damprob["CLOAK"] = 50    -- cloaking device       5.0%
    Param.damprob["XPORTER"] = 80  -- transporter           8.0%
    -- check to see if the sum of Param.damprob is 1000
    local sum = 0
    for k, v in pairs(Param.damprob) do
        sum = sum + v
    end
    if sum ~= 1000 then
        error(string.format("LUATREK SYSERR: Device probabilities sum to %d\n", sum))
    end
    Param.dockfac = 0.5
    Param.regenfac = (5 - Game.skill) * 0.05
    if Param.regenfac < 0.0 then
        Param.regenfac = 0.0
    end
    Param.warptime = 10
    Param.stopengy = 50
    Param.shupengy = 40
    Param.klingpwr = 100 + (150 * Game.skill)
    if Game.skill >= 6 then
        Param.klingpwr = Param.klingpwr + 150
    end
    Param.phasfac = 0.8
    Param.hitfac = 0.5
    Param.klingcrew = 200
    Param.srndrprob = 0.0035
    Param.moveprob[V.KM_OB] = 45
    Param.movefac[V.KM_OB] = .09
    Param.moveprob[V.KM_OA] = 40
    Param.movefac[V.KM_OA] = -0.05
    Param.moveprob[V.KM_EB] = 40
    Param.movefac[V.KM_EB] = 0.075
    Param.moveprob[V.KM_EA] = 25 + (5 * Game.skill)
    Param.movefac[V.KM_EA] = -0.06 * Game.skill
    Param.moveprob[V.KM_LB] = 0
    Param.movefac[V.KM_LB] = 0.0
    Param.moveprob[V.KM_LA] = 10 + (10 * Game.skill)
    Param.movefac[V.KM_LA] = 0.25
    Param.eventdly["E_SNOVA"] = 0.5;
    Param.eventdly["E_LRTB"] = 25.0;
    Param.eventdly["E_KATSB"] = 1.0;
    Param.eventdly["E_KDESB"] = 3.0;
    Param.eventdly["E_ISSUE"] = 1.0;
    Param.eventdly["E_SNAP"] = 0.5;
    Param.eventdly["E_ENSLV"] = 0.5;
    Param.eventdly["E_REPRO"] = 2.0;
    Param.navigcrud[0] = 1.50;
    Param.navigcrud[1] = 0.75;
    Param.cloakenergy = 1000;
    Param.energylow = 1000;
    for k, v in ipairs(Event) do
        Event[k].date = 1e50
        Event[k].evcode = ""
    end
    local xsched = trek.schedule.xsched
    xsched("E_SNOVA", 1, 0, 0, 0, false, false)
    xsched("E_LRTB", Param.klings, 0, 0, 0, false, false)
    xsched("E_KATSB", 1, 0, 0, 0, false, false)
    xsched("E_ISSUE", 1, 0, 0, 0, false, false)
    xsched("E_SNAP", 1, 0, 0, 0, false, false)
    Ship.sectx = math.random(V.NSECTS)
    Ship.secty = math.random(V.NSECTS)
    Game.killk = 0
    Game.kills = 0
    Game.killb = 0
    Game.deaths = 0
    Game.negenbar = 0
    Game.captives = 0
    Game.killinhab = 0
    Game.helps = 0
    Game.killed = false
    Game.snap = false
    Move.endgame = 0
    -- setup stars
    for i = 1, V.NQUADS do
        for j = 1, V.NQUADS do
            local q = Quad[i][j]
            local stars = math.random(1, 9)
            local holes = math.floor(math.random(0, 2) - (stars / 5))
            if holes < 0 then
                holes = 0
            end
            q.klings = 0
            q.bases = 0
            q.scanned = -1
            q.stars = stars
            q.holes = holes
            q.systemname = 0
        end
    end
    -- select inhabited starsystems
    for d = 1, #V.Systemname do
        local i, j, q
        repeat
            i = math.random(V.NQUADS)
            j = math.random(V.NQUADS)
            q = Quad[i][j]
        until q.systemname == 0
        q.systemname = d
        q.distressed = 0
    end
    -- position starbases
    for i = 1, Param.bases do
        local ix, iy, q
        repeat
            ix = math.random(V.NQUADS)
            iy = math.random(V.NQUADS)
            q = Quad[ix][iy]
        until q.bases == 0
        q.bases = 1
        Now.base[i].x = ix
        Now.base[i].y = iy
        q.scanned = 1001
        -- start the Enterprise near starbase
        if i == 1 then
            Ship.quadx = ix
            Ship.quady = iy
        end
    end
    -- position klingons
    local kleft = Param.klings
    while kleft > 0 do
        local klump = math.random(1, 4)
        if klump > kleft then
            klump = kleft
        end
        local ix, iy, q
        repeat
            ix = math.random(V.NQUADS)
            iy = math.random(V.NQUADS)
            q = Quad[ix][iy]
        until (q.klings + klump) <= V.MAXKLQUAD
        q.klings = q.klings + klump
        kleft = kleft - klump
    end
    -- initialize this quadrant
    pl.utils.printf("%d Klingons\n%d starbase", Param.klings, Param.bases)
    if Param.bases > 1 then
        pl.utils.printf("s")
    end
    pl.utils.printf(" at %d,%d", Now.base[1].x, Now.base[1].y)
    if Param.bases > 1 then
        for i = 2, Param.bases do
            pl.utils.printf(", %d,%d", Now.base[i].x, Now.base[i].y)
        end
    end
    pl.utils.printf("\nIt takes %d units to kill a Klingon\n", Param.klingpwr)
    Move.free = false
    trek.initquad.initquad(false)
    trek.scan.srscan(1)
    trek.klingon.attack(0)
    
    -- @todo more to go
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
