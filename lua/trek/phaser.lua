#!/usr/bin/env lua
--- Phaser control
-- @module trek.phaser
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
--- shorthand for pl.utils.printf
local printf = pl.utils.printf
--- shorthand for trek.damage.damaged
local damaged = function (ev) trek.damage.damaged(ev) end
--- local table of factors for phaser hits; see description below
-- Note: OMEGA ~= 100 * (ALPHA + 1) * (BETA + 1) / (EPSILON + 1)
-- @table phaser_factors
-- @field ALPHA spread
-- @field BETA math.random()
-- @field GAMMA cos(angle)
-- @field EPSILON (dist)^2
-- @field OMEGA overall scaling factor
local ALPHA = 3.0
local BETA = 3.0
local GAMMA = 0.30
local EPSILON =150.0
local OMEGA = 10.596
--- number of phaser banks
local NBANKS = 6
--- Phaser bank table
local bank = pl.tablex.new(NBANKS, 
    function (i)
        return {
            units = 0,
            angle = 0,
            spread = 0,
        }
    end
)
--- Phase mode command words
-- @table Matab
-- @field manual
-- @field automatic
local Matab = {
    ["auto"] = false,
    ["automatic"] = false,
    ["manual"] = true
}

--- Phaser Control:
-- there are up to NBANKS phaser banks which may be fired
-- simultaneously.  There are two modes, "manual" and
-- "automatic".  In manual mode, you specify exactly which
-- direction you want each bank to be aimed, the number
-- of units to fire, and the spread angle.  In automatic
-- mode, you give only the total number of units to fire.
--
-- The spread is specified as a number between zero and
-- one, with zero being minimum spread and one being maximum
-- spread.  You  will normally want zero spread, unless your
-- short range scanners are out, in which case you probably
-- don't know exactly where the Klingons are.  In that case,
-- you really don't have any choice except to specify a
-- fairly large spread.
--
-- Phasers spread slightly, even if you specify zero spread.
function M.phaser ()
    local hitreqd = pl.tablex.new(NBANKS, 0)
    if Ship.cond == "DOCKED" then
        printf("Phasers cannot fire through starbase shields\n")
        return
    end
    if damaged("PHASER") then
        trek.damage.out("PHASER")
        return
    end
    if Ship.shldup then
        printf("Sulu: Captain, we cannot fire through shields.\n")
        return
    end
    if Ship.cloaked then
        printf("Sulu: Captain, surely you must realize that we cannot fire\n")
        printf("  phasers with the cloaking device up.\n")
        return
    end
    -- decide if we want manual or automatic mode
    local manual = false
    if damaged("COMPUTER") then
        printf("%s", Device["COMPUTER"].name)
        manual = true
    elseif damaged("SRSCAN") then
        printf("%s", Device["SRSCAN"].name)
        manual = true
    end
    if manual then
        printf(" damaged, manual mode selected\n");
    else
        -- choose auto or manual
        local ptr = trek.getpar.getcodpar("Manual or automatic", Matab)
        manual = ptr
    end
    -- initialize the bank[] table
    local flag = true
    for i = 1, NBANKS do
        bank[i].units = 0
    end
    local extra
    if manual then
        -- collect manual mode statistics
        while flag do
            printf("%d units available\n", Ship.energy)
            extra = 0
            flag = false
            for i = 1, NBANKS do
                local b = bank[i]
                printf("\nBank %d:\n", i)
                local hit = trek.getpar.getnumpar("units")
                if hit < 0 then
                    return
                end
                if hit == 0 then
                    -- break the for loop
                    break
                end
                extra = extra + hit
                if extra > Ship.energy then
                    printf("available energy exceeded.  ")
                    flag = true
                    -- break the for loop
                    break
                end
                b.units = hit
                local course = trek.getpar.getintpar("course")
                if hit < 0 or hit >= 360 then
                    return
                end
                b.angle = course * math.pi / 180
                b.spread = trek.getpar.getintpar("spread")
                if b.spread < 0 or b.spread > 1 then
                    return
                end
            end
            Ship.energy = Ship.energy - extra
        end
        extra = 0
    else
        -- automatic distribution of power
        if Etc.nkling <= 0 then
            printf("Sulu: But there are no Klingons in this quadrant\n")
            return
        end
        printf("Phasers locked on target.  ")
        while flag do
            printf("%d units available\n", Ship.energy)
            local hit = trek.getpar.getnumpar("Units to fire")
            if hit <= 0 then
                return
            end
            if hit > Ship.energy then
                printf("available energy exceeded.  ")
            else
                -- assign the parameters to the phaser bank
                flag = false
                Ship.energy = Ship.energy - hit
                extra = hit
                local n = Etc.nkling
                if n > NBANKS then
                    n = NBANKS
                end
                local tot = math.floor(n * (n + 1) / 2)
                for i = 1, n do
                    local k = Etc.klingon[i]
                    local b = bank[i]
                    local distfactor = k.dist;
                    local anglefactor = ALPHA * BETA * OMEGA / 
                                        (distfactor * distfactor + EPSILON)
                    anglefactor = anglefactor * GAMMA
                    distfactor = k.power / anglefactor
                    hitreqd[i] = math.floor(distfactor + 0.5)
                    local dx = Ship.sectx - k.x
                    local dy = k.y - Ship.secty
                    b.angle = math.atan2(dy, dx)
                    b.spread = 0.0
                    b.units = math.floor(((n - i) / tot) * extra)
                    if V.Trace then
                        printf("b%d hr%d u%d df%.2f af%.2f\n",
                            i, hitreqd[i], b.units, distfactor, anglefactor)
                    end
                    extra = extra - b.units
                    hit = b.units - hitreqd[i]
                    if hit > 0 then
                        extra = extra + hit
                        b.units = b.units - hit
                    end
                end
            end
            -- give out any extra energy we might have around
            if extra > 0 then
                for i = 1, n do
                    local b = bank[i]
                    hit = hitreqd[i] - b.units
                    if hit > 0 then
                        if hit >= extra then
                            b.units = b.units + extra
                            extra = 0
                            -- break the for loop
                            break
                        end
                    end
                    b.units = hitreqd[i]
                    extra = extra - hit
                end
                if extra > 0 then
                    printf("%d units overkill\n", extra)
                end
            end
        end
    end
    if V.Trace then
        for i = 1, NBANKS do
            local b = bank[i]
            printf("b%d u%d", i, b.units)
            if b.units > 0 then
                printf(" a%.2f s%.2f\n", b.angle, b.spread)
            else
                printf("\n")
            end
        end
    end
    -- actually fire the shots
    Move.free = false
    for i = 1, NBANKS do
        local b = bank[i]
        if b.units > 0 then
            printf("\nPhaser bank %d fires:\n", i);
            local n = Etc.nkling
            local ki = 1
            local k = Etc.klingon[ki]
            for j = 1, n do
                if b.units <= 0 then
                    -- break the for loop
                    break
                end
                -- The formula for hit is as follows:
                --  zap = OMEGA * [(sigma + ALPHA) * (rho + BETA)]
                --        / (dist ^ 2 + EPSILON)]
                --        * [cos(delta * sigma) + GAMMA]
                --        * hit
                -- where sigma is the spread factor,
                -- rho is a random number (0 -> 1),
                -- GAMMA is a crud factor for angle (essentially
                -- cruds up the spread factor),
                -- delta is the difference in radians between the
                -- angle you are shooting at and the actual
                -- angle of the klingon,
                -- ALPHA scales down the significance of sigma,
                -- BETA scales down the significance of rho,
                -- OMEGA is the magic number which makes everything
                -- up to "* hit" between zero and one,
                -- dist is the distance to the klingon
                -- hit is the number of units in the bank, and
                -- zap is the amount of the actual hit.
                --
                -- Everything up through dist squared should maximize
                -- at 1.0, so that the distance factor is never
                -- greater than one.  Conveniently, cos() is
                -- never greater than one, but the same restriction
                -- applies.
                local distfactor = BETA + math.random()
                distfactor = distfactor * (ALPHA + b.spread) * OMEGA
                local anglefactor = k.dist
                distfactor = distfactor / (anglefactor * anglefactor + EPSILON)
                distfactor = distfactor * b.units
                local dx = Ship.sectx - k.x
                local dy = k.y - Ship.secty
                anglefactor = math.atan2(dy, dx) - b.angle
                anglefactor = math.cos((anglefactor * b.spread) + GAMMA)
                if anglefactor >= 0.0 then
                    hit = math.floor(anglefactor * distfactor + 0.5)
                    k.power = k.power - hit
                    printf("%d unit hit on Klingon", hit)
                    if not damaged("SRSCAN") then
                        printf(" at %d,%d", k.x, k.y)
                    end
                    printf("\n")
                    b.units = b.units - hit
                    if k.power <= 0 then
                        trek.kill.killk(k.x, k.y)
                    end
                end
                ki = ki + 1
            end
        end
    end
    -- compute overkill
    for i = 1, NBANKS do
        extra = extra + bank[i].units
    end
    if extra > 0 then
        printf("\n%d units expended on empty space\n", extra)
    end
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
