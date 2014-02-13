#!/usr/bin/env lua
--- Compute Klingon attacks, moves, and distance computation
-- @module trek.klingon
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
--- Global Device table
local Etc = V.Etc
--- Global Device table
local Device = V.Device
--- shorthand for Penlight printf
local printf = pl.utils.printf

--- Sort klingons:
-- bubble sort on ascending distance
local function sortkl ()
    local m = Etc.nkling - 1
    local f = true
    while f do
        f = false
        for i = 1, m do
            if Etc.klingon[i].dist > Etc.klingon[i + 1].dist then
                local t = Etc.klingon[i]
                Etc.klingon[i] = Etc.klingon[i + 1]
                Etc.klingon[i + 1] = t
                f = true
            end
        end
    end
end

--- Compute klingon distances:
-- the klingon list has the distances for all klingons recomputed
-- and sorted.  The parameter is a Boolean flag which is set if
-- have just entered a new quadrant.
--
-- This routine is used every time the Enterprise or the Klingons
-- move.
-- @bool f true if just entered a new quadrant, false if not
function M.compkldist (f)
    if Etc.nkling == 0 then
        return
    end
    for i = 1, Etc.nkling do
        local dx = Ship.sectx - Etc.klingon[i].x
        local dy = Ship.secty - Etc.klingon[i].y
        local d = math.sqrt((dx * dx) + (dy * dy))
        -- compute average of new and old distances to Klingon
        if not f then
            Etc.klingon[i].avgdist = 0.5 * (Etc.klingon[i].dist + d)
        else
            -- new quadrant: average is current
            Etc.klingon[i].avgdist = d
        end
        Etc.klingon[i].dist = d
    end
    -- leave them sorted
    sortkl()
    -- trace code to dump klingons in the sector
    if V.Trace then
        for i = 1, Etc.nkling do
            printf("compkldist: klingon %d: x = %d, y = %d\n",
                i, Etc.klingon[i].x, Etc.klingon[i].y)
        end
    end
end

--- Move Klingons Around:
-- this is a largely incomprehensible block of code that moves
-- Klingons around in a quadrant.  It was written in a very
-- "program as you go" fashion, and is a prime candidate for
-- rewriting.
--
-- The flag fl shows "before" or "after" an attack.
-- This serves to change the probability and distance that it moves.
--
-- Basically, what it will try to do is to move a certain number
-- of steps either toward you or away from you.  It will avoid
-- stars whenever possible.  Nextx and nexty are the next
-- sector to move to on a per-Klingon basis; they are roughly
-- equivalent to Ship.sectx and Ship.secty for the starship.  Lookx and
-- looky are the sector that you are going to look at to see
-- if you can move their.  Dx and dy are the increment.  Fudgex
-- and fudgey are the things you change around to change your
-- course around stars.
-- @string fl "BEFORE" an attack or "AFTER" an attack
function M.klmove (fl)
    if V.Trace then
        printf("klmove: fl = %s, Etc.nkling = %d\n", fl, Etc.nkling)
    end
    for n = 1, Etc.nkling do
        local stayquad = true
        -- if V.Trace then
        --    printf("klmove: processing klingon number %d\n", n)
        -- end
        local i = 100
        if fl == "AFTER" then
            i = math.floor(100.0 * Etc.klingon[n].power / Param.klingpwr)
        end
        local ii
        if i <= 1 then
            ii = 0
        else
            ii = math.random(0, i - 1)
        end
        if ii < Param.moveprob[Move.newquad][fl] then
            -- continue the for loop
            if V.Trace then
                printf("klmove: klingon number %d did not move\n", n)
            end
            goto endofloop
        end
        -- compute distance to move
        local motion = math.random(-25, 49)
        motion = math.floor(motion * Etc.klingon[n].avgdist * 
                            Param.movefac[Move.newquad][fl])
        -- compute direction
        local dx = Ship.sectx - Etc.klingon[n].x + math.random(-1, 1)
        local dy = Ship.secty - Etc.klingon[n].y + math.random(-1, 1)
        local bigger = dx
        if dy > bigger then
            bigger = dy
        end
        if bigger == 0.0 then
            bigger = 1.0
        end
        dx = (dx / bigger) + 0.5
        dy = (dy / bigger) + 0.5
        if motion < 0 then
            motion = -motion
            dx = -dx
            dy = -dy
        end
        if V.Trace then
            printf("klmove: dx = %.2f, dy = %.2f, motion = %d\n", dx, dy, motion)
        end
        local fudgex = 1
        local fudgey = 1
        -- try to move the klingon
        local nextx = Etc.klingon[n].x
        local nexty = Etc.klingon[n].y
        stayquad = true
        -- if V.Trace then
        --    printf("klmove: nextx = %d, nexty = %d\n", nextx, nexty)
        -- end
        for d = 1, motion do
            local lookx = math.floor(nextx + dx)
            local looky = math.floor(nexty + dy)
            -- if V.Trace then
            --    printf("klmove: d = %d, lookx = %d, looky = %d\n", d, lookx, looky)
            -- end
            if lookx < 0 or lookx >= V.NSECTS or
                    looky < 0 or looky >= V.NSECTS then
                -- new quadrant
                local qx = Ship.quadx
                local qy = Ship.quady
                if lookx < 0 then
                    qx = qx - 1
                elseif lookx >= V.NSECTS then
                    qx = qx + 1
                end
                if looky < 0 then
                    qy = qy - 1
                elseif looky >= V.NSECTS then
                    qy = qy + 1
                end
                if qx < 0 or qx >= V.NQUADS or
                   qy < 0 or qy >= V.NQUADS or
                   Quad[qx + 1][qy + 1].stars < 0 or
                   Quad[qx + 1][qy + 1].klings > V.MAXKLQUAD - 1 then
                   -- break from the for loop
                   break
                end
                if not trek.damage.damaged("SRSCAN") then
                    printf("Klingon at %d,%d escapes to quadrant %d,%d\n",
                            Etc.klingon[n].x, Etc.klingon[n].y,
                            qx, qy)
                    local code = Quad[qx + 1][qy + 1].scanned
                    if code >= 0 and code < 1000 then
                        Quad[qx + 1][qy + 1].scanned = 
                            Quad[qx + 1][qy + 1].scanned + 100
                    end
                    local codeq = Quad[Ship.quadx + 1][Ship.quady + 1].scanned
                    if codeq >= 0 and codeq < 1000 then
                        Quad[Ship.quadx + 1][Ship.quady + 1].scanned =
                            Quad[Ship.quadx + 1][Ship.quady + 1].scanned - 100
                    end
                end
                Sect[Etc.klingon[n].x + 1][Etc.klingon[n].y + 1] = "EMPTY"
                Quad[qx + 1][qy + 1].klings = Quad[qx + 1][qy + 1].klings + 1
                -- Old index range: 1 to oldnkling
                -- Etc.klingon[n] is no longer valid
                -- copy Etc.klingon[Etc.nkling] contents to Etc.klingon[n]
                -- and decrement Etc.nkling by one
                -- New index range: 1 to (oldnkling - 1)
                local oldnkling = Etc.nkling
                -- do not erase but overwrite the table elements
                Etc.klingon[n] = pl.tablex.deepcopy(Etc.klingon[oldnkling])
                Etc.nkling = oldnkling - 1
                Quad[Ship.quadx + 1][Ship.quady + 1].klings =
                    Quad[Ship.quadx + 1][Ship.quady + 1].klings - 1
                stayquad = false
                -- break from the for loop
                break
            end
            if Sect[lookx + 1][looky + 1] ~= "EMPTY" then
                lookx = nextx + fudgex
                if lookx < 0 or lookx >= V.NSECTS then
                    lookx = math.floor(nextx + dx)
                end
                if Sect[lookx + 1][looky + 1] ~= "EMPTY" then
                    fudgex = -fudgex
                    looky = nexty + fudgey
                    if looky < 0 or looky >= V.NSECTS or
                       Sect[lookx + 1][looky + 1] ~= "EMPTY" then
                       fudgey = -fudgey
                       -- break from the for loop
                       break
                    end
                end
            end
            nextx = lookx
            nexty = looky
            -- if V.Trace then
            --    printf("klmove: nextx = %d, nexty = %d\n", nextx, nexty)
            -- end
        end
        if stayquad and 
            (Etc.klingon[n].x ~= nextx or Etc.klingon[n].y ~= nexty) then
            if not trek.damage.damaged("SRSCAN") then
                -- detect non-number
                -- @todo should be %d
                printf("Klingon at %s,%s moves to %s,%s\n", 
                        Etc.klingon[n].x, Etc.klingon[n].y, nextx, nexty)
            end
            Sect[Etc.klingon[n].x + 1][Etc.klingon[n].y + 1] = "EMPTY"
            Etc.klingon[n].x = nextx
            Etc.klingon[n].y = nexty
            Sect[Etc.klingon[n].x + 1][Etc.klingon[n].y + 1] = "KLINGON"
        end
        ::endofloop::
    end
    M.compkldist(0)
end

--- Klingon Attack Routine:
-- this routine performs the Klingon attack provided that
-- (1) Something happened this move (i.e., not free), and
-- (2) You are not cloaked.  Note that if you issue the
-- cloak command, you are not considered cloaked until you
-- expend some time.
--
-- Klingons are permitted to move both before and after the
-- attack.  They will tend to move toward you before the
-- attack and away from you after the attack.
--
-- Under certain conditions you can get a critical hit.  This
-- sort of hit damages devices.  The probability that a given
-- device is damaged depends on the device.  Well protected
-- devices (such as the computer, which is in the core of the
-- ship and has considerable redundancy) almost never get
-- damaged, whereas devices which are exposed (such as the
-- warp engines) or which are particularly delicate (such as
-- the transporter) have a much higher probability of being
-- damaged.
--
-- The actual amount of damage (i.e., how long it takes to fix
-- it) depends on the amount of the hit and the "damfac[]"
-- entry for the particular device.
--
-- Casualties can also occur.
-- @bool resting true if attack while resting
function M.attack (resting)
    if Move.free then
        return
    end
    if Etc.nkling <= 0 or
       Quad[Ship.quadx + 1][Ship.quady + 1].stars < 0 then
        return
    end
    if Ship.cloaked and Ship.cloakgood then
        return
    end
    -- move before attack
    M.klmove("BEFORE")
    if Ship.cond == "DOCKED" then
        if not resting then
            printf("Starbase shields protect the %s\n", Ship.shipname)
            return
        end
    end
    -- setup shield effectiveness
    local chgfac = 1.0;
    if Move.shldchg then
        chgfac = 0.25 + 0.50 * math.random()
    end
    local tothit = 0
    local maxhit = 0
    local hitflag = false
    -- let each Klingon do the damndest
    for i = 1, Etc.nkling do
        -- if the klingon is low on power it won't attack
        if Etc.klingon[i].power < 20 then
           break
        end
        if not hitflag then
            printf("\nStardate %.2f: Klingon attack:\n", Now.date)
            hitflag = true
        end
        -- complete the hit
        local dustfac = 0.90 + 0.01 * math.random()
        local tothe = Etc.klingon[i].avgdist
        local hit = Etc.klingon[i].power * math.pow(dustfac, tothe) * Param.hitfac
        -- deplete the energy
        Etc.klingon[i].power = Etc.klingon[i].power *
            (Param.phasfac * (1.0 + (math.random() - 0.5) * 0.2))
        -- see how much of hit shields will absorb
        local shldabsb = 0;
        if Ship.shldup or Move.shldchg then
            local propor = Ship.shield / Param.shield
            shldabsb = math.floor(propor * chgfac * hit)
            if shldabsb > Ship.shield then
                shldabsb = Ship.shield
            end
            Ship.shield = Ship.shield - shldabsb
        end
        -- actually do the hit
        printf("*** HIT: %d units", hit)
        if not trek.damage.damaged("SRSCAN") then
            printf(" from %d,%d", Etc.klingon[i].x, Etc.klingon[i].y)
        end
        local cas = math.floor((shldabsb * 100) / hit)
        hit = hit - shldabsb
        if shldabsb > 0 then
            printf(", shields absorb %d%%, effective hit %d\n", cas, hit)
        else
            printf("\n")
        end
        tothit = tothit + hit
        if hit > maxhit then
            maxhit = hit
        end
        Ship.energy = Ship.energy - hit
        -- see if damages occurred
        if hit >= ((15 - Game.skill) * math.random(14, 25)) then
            printf("*** CRITICAL HIT!!! ***\n")
            -- select a device from probability vector
            cas = math.random(0, 999)
            local dev = ""
            for k, v in pairs(Param.damprob) do
                if (cas < v) then
                    dev = k
                    break
                else
                    cas = cas - v
                end
            end
            -- compute amount of damage
            local extradm = (hit * Param.damfac[dev]) / math.random(75, 99) + 0.5
            -- damage the device
            trek.damage.damage(dev, extradm)
            if trek.damage.damaged("SHIELD") then
                if Ship.shldup then
                    printf("Sulu: Shields knocked down, captain.\n")
                end
                Ship.shldup = false
                Move.shldchg = false
            end
        end
        if Ship.energy <= 0 then
            trek.score.lose("L_DSTRYD")
        end
    end
    -- see what our casualities are like
    if maxhit >= 200 or tothit >= 500 then
        local cas = math.floor(tothit * 0.015 * math.random())
        if cas >= 2 then
            printf("McCoy: we suffered %d casualties in that attack.\n", cas)
            Game.deaths = Game.deaths + cas
            Ship.crew = Ship.crew - cas
        end
    end
    -- allow Klingons to move after attacking
    M.klmove("AFTER")
    return
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
