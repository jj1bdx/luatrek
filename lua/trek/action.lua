#!/usr/bin/env lua
--- Miscellaneous action handler including cruise computer control
-- @module trek.action
-- @alias M

-- Luatrek license statement
--[[
Luatrek ("this software") is covered under the BSD 3-clause license.

This product includes software developed by the University of California, Berkeley
and its contributors.

Copyright (c) 2013-2022 Kenji Rikitake. All rights reserved.

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

local Cputab = {
--- local table of commands and the specified functions
-- @table Cputab
-- @field command-names
    ["ch"] = 1,
    ["chart"] = 1,
    ["t"] = 2,
    ["trajectory"] = 2,
    ["c"] = 3.0,
    ["course"] = 3.0,
    ["m"] = 3.1,
    ["move"] = 3.1,
    ["sc"] = 4,
    ["score"] = 4,
    ["p"] = 5,
    ["pheff"] = 5,
    ["w"] = 6,
    ["warpcost"] = 6,
    ["i"] = 7,
    ["impcost"] = 7,
    ["d"] = 8,
    ["distresslist"] = 8,
    ["q"] = 9,
    ["quit"] = 9,
    ["s"] = 10,
    ["sr"] = 10,
    ["srscan"] = 10,
}

--- Course Calculation:
-- computes and outputs the course and distance from position
-- sqx,sqy/ssx,ssy to tqx,tqy/tsx,tsy, normalized to quadrant distance.
-- @int tqx target Quadrant coordinate X
-- @int tqy target Quadrant coordinate Y
-- @int tsx target Sector coordinate X
-- @int tsy target Sector coordinate Y
-- @treturn num Course
-- @treturn num Distance
local function kalc (tqx, tqy, tsx, tsy)
    -- normalize to quadrant distances
    local quadsize = V.NSECTS
    local dx = (Ship.quadx + (Ship.sectx / quadsize)) - (tqx + (tsx / quadsize))
    local dy = (tqy + (tsy / quadsize)) - (Ship.quady + (Ship.secty / quadsize))
    -- get the angle
    local angle = math.atan2(dy, dx)
    -- make it 0 to 2 * pi
    if angle < 0.0 then
        angle = angle + (math.pi * 2)
    end
    -- convert from radians to degrees
    local course = math.floor(angle * (180 / math.pi) + 0.5)
    local dist = math.sqrt(dx * dx + dy * dy)
    return course, dist
end

--- Print course and distance
-- @int course Course
-- @number dist Distance
local function prkalc (course, dist)
    printf(": course %d  dist %.3f\n", course, dist)
end

--- On-Board Computer:
-- A computer request is fetched from the captain.  The requests
-- are:
-- 
-- * chart -- print a star chart of the known galaxy.
--     This includes
--     every quadrant that has ever had a long range or
--     a short range scan done of it, plus the location of
--     all starbases.  This is of course updated by any sub-
--     space radio broadcasts (unless the radio is out).
--     The format is the same as that of a long range scan
--     except that ".1." indicates that a starbase exists
--     but we know nothing else.
-- * trajectory -- gives the course and distance to every know
--     Klingon in the quadrant.  Obviously this fails if the
--     short range scanners are out.
-- * course -- gives a course computation from whereever you are
--     to any specified location. 
--     The input is quadrant and sector coordinates
--     of the target sector.  Separate the numbers by spaces.
-- * move -- identical to course, except that the move is performed.
-- * score -- prints out the current score.
-- * pheff -- "PHaser EFFectiveness" at a given distance.  Tells
--     you how much stuff you need to make it work.
-- * warpcost -- Gives you the cost in time and units to move for
--     a given distance under a given warp speed.
-- * impcost -- Same for the impulse engines.
-- * distresslist -- Gives a list of the currently known starsystems
--     or starbases which are distressed, together with their
--     quadrant coordinates.
-- * quit -- exiting the computer
-- * srscan -- Short range scan is available in the computer also.
--     Note well that you will be attacked *after* exiting the computer.
function M.computer()
    if trek.damage.check_out("COMPUTER") then
        return
    end
    while true do
        local r = trek.getpar.getcodpar("Request", Cputab);
        if r == 1 then
            -- star chart
            printf("Computer record of galaxy for all long range sensor scans\n\n")
            printf("  ")
            -- print top header
            for i = 0, V.NQUADS - 1 do
                printf("-%d- ", i)
            end
            printf("\n")
            for i = 0, V.NQUADS - 1 do
                printf("%d ", i)
                for j = 0, V.NQUADS - 1 do
                    if i == Ship.quadx and j == Ship.quady then
                        printf("$$$ ")
                    else
                        local q = Quad[i + 1][j + 1]
                        -- 1000 or 1001 is special case
                        if q.scanned >= 1000 then
                            if q.scanned > 1000 then
                                printf(".1. ")
                            else
                                printf("/// ")
                            end
                        else
                            if q.scanned < 0 then
                                printf("... ")
                            else
                                printf("%3d ", q.scanned)
                            end
                        end
                    end
                end
                printf("%d\n", i)
            end
            printf("  ")
            -- print bottom footer
            for i = 0, V.NQUADS - 1 do
                printf("-%d- ", i)
            end
            printf("\n");
        elseif r == 2 then
            -- trajectory
            if not trek.damage.check_out("SRSCAN") then
                if Etc.nkling <= 0 then
                    printf("No Klingons in this quadrant\n")
                else
                    -- for each Klingon, give the course & distance
                    for i = 1, Etc.nkling do
                        printf("Klingon at %d,%d", Etc.klingon[i].x, Etc.klingon[i].y)
                        local course, dist = kalc(Ship.quadx, Ship.quady,
                                        Etc.klingon[i].x, Etc.klingon[i].y)
                        prkalc(course, dist)
                    end
                end
            end
        elseif r == 3.0 or r == 3.1 then
            -- course calculation
            local valid = false
            local num, tab = trek.getpar.getwords("Quadrant X, Y, Sector X, Y");
            local tqx, tqy, ix, iy
            if num ~= 4 then
                printf("Split four numbers by space\n")
            else
                tqx = tonumber(tab[1])
                tqy = tonumber(tab[2])
                ix = tonumber(tab[3])
                iy = tonumber(tab[4])
                if tqx == nil or tqy == nil or
                   ix == nil or iy == nil then
                    printf("Invalid coordinate number entered\n")
                elseif tqx < 0 or tqx > V.NQUADS - 1 or
                   tqy < 0 or tqy > V.NQUADS - 1 or
                   ix < 0 or ix > V.NSECTS - 1 or
                   iy < 0 or iy > V.NSECTS - 1 then
                    printf("Coordinate out of range\n")
                end
                valid = true
            end
            if valid then
                local course, dist = kalc(tqx, tqy, ix, iy)
                if r == 3.1 then
                    trek.move.warp(-1, course, dist)
                else
                    printf("%d,%d/%d,%d to %d,%d/%d,%d",
                        Ship.quadx, Ship.quady, Ship.sectx, Ship.secty, tqx, tqy, ix, iy)
                    prkalc(course, dist)
                end
            end
        elseif r == 4 then
            -- score
            trek.score.score()
        elseif r == 5 then
            -- phaser effectiveness
            local dist = trek.getpar.getnumpar("range")
            if dist >= 0 then
                dist = dist * 10.0
                local cost = math.floor(math.pow(0.90, dist) * 98.0 + 0.5)
                printf("Phasers are %d%% effective at that range\n", cost)
            end
        elseif r == 6 then
            -- warp cost (time/energy)
            local dist = trek.getpar.getnumpar("distance")
            if dist >= 0 then
                local warpfact = trek.getpar.getfltpar("warp factor")
                if warpfact <= 0.0 then
                    warpfact = Ship.warp
                end
                local cost = math.floor((dist + 0.05) * warpfact * warpfact * warpfact)
                local p_time = Param.warptime * dist / (warpfact * warpfact)
                printf("Warp %.2f distance %.2f cost %.2f stardates %d (%d w/ shlds up) units\n",
                    warpfact, dist, p_time, cost, cost + cost);
            end
        elseif r == 7 then
            -- impluse cost
            local dist = trek.getpar.getnumpar("distance")
            if dist >= 0 then
                local cost = math.floor(20 + 100 * dist)
                local p_time = dist / 0.095
                printf("Distance %.2f cost %.2f stardates %d units\n",
                    dist, p_time, cost)
            end
        elseif r == 8 then
            -- distresslist
            local distress = false
            printf("\n");
            -- scan the event list
            for i = 1, V.MAXEVENTS do
                local e = Event[i]
                -- ignore hidden entries
                if not e.hidden then
                    if e.evcode == "E_KDESB" then
                        printf("Klingon is attacking starbase in quadrant %d,%d\n",
                            e.x, e.y)
                        distress = true
                    elseif e.evcode == "E_ENSLV" or
                        e.evcode == "E_REPRO" then
                        printf("Starsystem %s in quadrant %d,%d is distressed\n",
                            V.Systemname[e.systemname], e.x, e.y)
                        distress = true
                    end
                end
            end
            if not distress then
                printf("No known distress calls are active\n")
            end
        elseif r == 9 then
            -- quit the computer and go back to the command loop
            printf("Exiting the computer\n")
            return
        elseif r == 10 then
            -- short range scanner
            trek.scan.srscan(1)
        end
    end
end

--- Abandon Ship:
-- the ship is abandoned.  If your current ship is the Faire
-- Queene, or if your shuttlecraft is dead, you're out of
-- luck.  You need the shuttlecraft in order for the captain
-- (that's you!!) to escape.
--
-- Your crew can beam to an inhabited starsystem in the
-- quadrant, if there is one and if the transporter is working.
-- If there is no inhabited starsystem, or if the transporter
-- is out, they are left to die in outer space.
--
-- These currently just count as regular deaths, but they
-- should count very heavily against you.
--
-- If there are no starbases left, you are captured by the
-- Klingons, who torture you mercilessly.  However, if there
-- is at least one starbase, you are returned to the
-- Federation in a prisoner of war exchange.  Of course, this
-- can't happen unless you have taken some prisoners.
function M.abandon ()
    if Ship.ship == "QUEENE" then
        printf("You may not abandon ye Faire Queene\n")
        return
    end
    if Ship.cond ~= "DOCKED" then
        if damaged("SHUTTLE") then
            trek.damage.out("SHUTTLE")
            return
        end
        printf("Officers escape in shuttlecraft\n")
        -- decide on fate of crew
        local q = Quad[Ship.quadx + 1][Ship.quady + 1]
        if q.systemname == 0 or damaged("XPORTER") then
            printf("Entire crew of %d left to die in outer space\n",
                Ship.crew)
            Game.deaths = Game.deaths + Ship.crew
        else
            printf("Crew beams down to planet %s\n",
                    V.Systemname[q.systemname])
        end
    end
    -- see if you can be exchanged
    if Now.bases == 0 or (Game.captives < 20 * Game.skill) then
        trek.score.lose("L_CAPTURED")
    end
    -- re-outfit new ship
    printf("You are hereby put in charge of an antiquated but still\n")
    printf("  functional ship, the Fairie Queene.\n")
    Ship.ship = "QUEENE"
    Ship.shipname = "Fairie Queene"
    Param.energy = 3000
    Ship.energy = Param.energy
    Param.torped = 6
    Ship.torped = Param.torped
    Param.shield = 1250
    Ship.shield = Param.shield
    Ship.shldup = false
    Ship.cloaked = false
    Ship.warp = 5.0
    Ship.warp2 = 25.0
    Ship.warp3 = 125.0
    Ship.cond = "GREEN"
    -- clear out damages on old ship
    for i = 1, V.MAXEVENTS do
        local e = Event[i]
        if e.evcode == "E_FIXDV" then
            trek.schedule.unschedule(e)
        end
    end
    -- get rid of some devices and redistribute probabilities
    local i = Param.damprob[SHUTTLE] + Param.damprob[CLOAK]
    Param.damprob[SHUTTLE] = 0
    Param.damprob[CLOAK] = 0
    while i > 0 do
        for k, v in pairs(Param.damprob) do
            if v > 0 then
                Param.damprob[k] = v + 1
                i = i - 1
                if i <= 0 then
                    -- break from for loop
                    break
                end
            end
        end
    end
    -- pick a starbase to restart at
    i = math.random(1, Now.bases)
    Ship.quadx = Now.base[i].x
    Ship.quady = Now.base[i].y
    -- setup that quadrant
    while true do
        trek.initquad.initquad(true)
        Sect[Ship.sectx + 1][Ship.secty + 1] = "EMPTY"
        for i = 1, 5 do
            Ship.sectx = Etc.starbase.x + math.random(-1, 1)
            if Ship.sectx >= 0 and Ship.sectx <= NSECTS - 1 then
                Ship.secty = Etc.starbase.y + math.random(-1, 1)
                if Ship.secty >= 0 and Ship.secty <= NSECTS - 1 then
                    if Sect[Ship.sectx + 1][Ship.secty + 1] == "EMPTY" then
                        Sect[Ship.sectx + 1][Ship.secty + 1] = "QUEENE"
                        trek.dock.dock()
                        trek.klingon.compkldist(false)
                        return
                    end
                end
            end
        end
    end
end

--- Ask a Klingon To Surrender
-- (Fat chance) :
-- the Subspace Radio is needed to ask a Klingon if he will kindly
-- surrender.  A random Klingon from the ones in the quadrant is
-- chosen.
--
-- The Klingon is requested to surrender.  The probability of this
-- is a function of that Klingon's remaining power, our power,
-- etc.
function M.capture ()
    -- check for not cloaked
    if Ship.cloaked then
        printf("Ship-ship communications out when cloaked\n")
        return
    end
    if damaged("SSRADIO") then
        trek.damage.out("SSRADIO")
        return
    end
    -- find out if there are any at all
    if Etc.nkling <= 0 then
        printf("Uhura: Getting no response, sir\n")
        return
    end
    -- if there is more than one Klingon, find out which one
    -- The algorithm is cruddy, just takes one at random.i
    -- Should ask the captain.
    local i
    if (Etc.nkling < 2) then
        i = 1
    else
        i = math.random(1, Etc.nkling)
    end
    local k = Etc.klingon[i]
    Move.free = false
    Move.time = 0.05
    -- check out that Klingon
    k.srndreq = true
    local x = Param.klingpwr
    x = x * Ship.energy
    x = x / (k.power * Etc.nkling)
    x = x * Param.srndrprob
    i = math.floor(x)
    if V.Trace then
        printf("Prob = %d (%.4f)\n", i, x)
    end
    if i > math.random(0, 99) then
        -- guess what, the Klingon surrendered!!!
        printf("Klingon at %d,%d surrenders\n", k.x, k.y)
        local j = math.random(0, Param.klingcrew - 1)
        if j > 0 then
            printf("%d klingons commit suicide rather than be taken captive\n", Param.klingcrew - j)
        end
        if j > Ship.brigfree then
            j = Ship.brigfree
        end
        Ship.brigfree = Ship.brigfree - j
        printf("%d captives taken\n", j)
        trek.kill.killk(k.x, k.y)
        return
    end
    -- big surprise, he refuses to surrender
    printf("Fat chance, captain\n")
    return
end

--- Call starbase for help:
-- first, the closest starbase is selected.  If there is a
-- a starbase in your own quadrant, you are in good shape.
-- This distance takes quadrant distances into account only.
--
-- A magic number is computed based on the distance which acts
-- as the probability that you will be rematerialized.  You
-- get three tries.
--
-- When it is determined that you should be able to be remater-
-- ialized (i.e., when the probability thing mentioned above
-- comes up positive), you are put into that quadrant (anywhere).
-- Then, we try to see if there is a spot adjacent to the star-
-- base.  If not, you can't be rematerialized!!!  Otherwise,
-- it drops you there.  It only tries five times to find a spot
-- to drop you.  After that, it's your problem.
function M.help ()
    local Cntvect = {"first", "second", "third"}
    -- check to see if calling for help is reasonable ...
    if Ship.cond == "DOCKED" then
        printf("Uhura: But Captain, we're already docked\n")
        return
    end
    -- or possible
    if damaged("SSRADIO") then
        trek.damage.out("SSRADIO")
        return
    end
    if Now.bases <= 0 then
        printf("Uhura: I'm not getting any response from starbase\n")
        return
    end
    -- tut tut, there goes the score
    Game.helps = Game.helps + 1
    -- find the closest base
    local dist = 1e50;
    local l, x
    if Quad[Ship.quadx + 1][Ship.quady + 1].bases <= 0 then
        -- there isn't one in this quadrant
        for i = 1, Now.bases do
            -- compute distance
            local dx = Now.base[i].x - Ship.quadx
            local dy = Now.base[i].y - Ship.quady
            x = math.sqrt(dx * dx + dy * dy)
            -- see if better than what we already have
            if x < dist then
                dist = x
                l = i;
            end
        end
        -- go to that quadrant
        Ship.quadx = Now.base[l].x
        Ship.quady = Now.base[l].y
        trek.initquad.initquad(true)
    else
        dist = 0.0
    end
    -- dematerialize the Enterprise
    Sect[Ship.sectx + 1][Ship.secty + 1] = "EMPTY"
    printf("Starbase in %d,%d responds\n", Ship.quadx, Ship.quady)
    -- this next thing acts as a probability that it will work */
    x = math.pow(1.0 - math.pow(0.94, dist), 0.3333333)
    -- attempt to rematerialize
    for i = 1, 3 do
        printf("%s attempt to rematerialize ", Cntvect[i])
        if math.random() > x then
            -- ok, that's good.  let's see if we can set the ship down
            local found = false
            local dx, dy
            for j = 1, 5 do
                dx = Etc.starbase.x + math.random(-1, 1)
                if dx >= 0 and dx <= V.NSECTS - 1 then
                    dy = Etc.starbase.x + math.random(-1, 1)
                    if dx >= 0 and dx <= V.NSECTS - 1 and
                        Sect[dx + 1][dy + 1] == "EMPTY" then
                        found = true
                        -- break from for loop
                        break
                    end
                end
            end
            if found then
                -- found an empty spot
                printf("succeeds\n")
                Ship.sectx = dx
                Ship.secty = dy
                Sect[dx + 1][dy + 1] = Ship.ship
                trek.dock.dock()
                trek.klingon.compkldist(false)
                return
            end
            -- the starbase must have been surrounded
        end
        printf("fails\n")
    end
    -- one, two, three strikes, you're out
    trek.score.lose("L_NOHELP")
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
