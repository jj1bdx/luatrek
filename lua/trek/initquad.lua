#!/usr/bin/env lua
--- Quadrant and sector data initialization
-- @module trek.initquad
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
--- Global Etc table
local Etc = V.Etc

--- Parameterize quadrant upon entering:
-- a quadrant is initialized from the information held in the
-- Quad matrix.  Basically, everything is just initialized
-- randomly, except for the starship, which goes into a fixed
-- sector.
--
-- If there are Klingons in the quadrant, the captain is informed
-- that the condition is RED, and the captain is given a chance to put
-- the shields up if the computer is working.
--
-- @bool f The flag `f' is set to disable the check for condition red.
-- This mode is used in situations where you know you are going
-- to be docked, i.e., abandon() and help().
function M.initquad (f)
    local q = Quad[Ship.quadx][Ship.quady]
    -- ignored supernova'ed quadrants (this is checked again later anyway)
    if q.stars < 0 then
        return
    end
    -- load quadrant state
    Etc.nkling = q.klings
    local nbases = q.bases
    local nstars = q.stars
    local nholes = q.holes
    -- have we blundered into a battle zone w/ shields down?
    if Etc.nkling > 0 and f == false then
        pl.utils.printf("Condition RED\n")
        Ship.cond = "RED"
        if not trek.damage.damaged("COMPUTER") then
            trek.shield.shield(1);
        end
    end
    -- clear out the quadrant
    for i = 1, V.NSECTS do
        for j = 1, V.NSECTS do
            Sect[i][j] = "EMPTY"
        end
    end
    -- initialize Enterprise
    Sect[Ship.sectx][Ship.secty] = Ship.ship
    -- initialize Klingons
    for i = 1, Etc.nkling do
        local rx, ry = M.sector()
        Sect[rx][ry] = "KLINGON"
        Etc.klingon[i].x = rx
        Etc.klingon[i].y = ry
        Etc.klingon[i].power = Param.klingpwr
        Etc.klingon[i].srndreq = 0
    end
    trek.klingon.compkldist(true)
    -- initialize star base
    if nbases > 0 then
        local rx, ry = M.sector()
        Sect[rx][ry] = "BASE"
        Etc.starbase.x = rx
        Etc.starbase.y = ry
    end
    -- initialize inhabited starsystem
    if q.systemname ~= 0 then
        local rx, ry = M.sector()
        Sect[rx][ry] = "INHABIT"
        -- Inhabited star is a star anyway
        nstars = nstars - 1
    end
    -- initialize black holes
    for i = 1, nholes do
        local rx, ry = M.sector()
        Sect[rx][ry] = "HOLE"
    end
    -- initialize stars
    for i = 1, nstars do
        local rx, ry = M.sector()
        Sect[rx][ry] = "STAR"
    end
    Move.newquad = 1
end

--- Choose first empty sector point and return the coordinates
-- @treturn int Sector coordinate X
-- @treturn int Sector coordinate Y
function M.sector ()
    local i, j
    repeat
        i = math.random(1, V.NSECTS)
        j = math.random(1, V.NSECTS)
    until Sect[i][j] == "EMPTY"
    return i, j
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
