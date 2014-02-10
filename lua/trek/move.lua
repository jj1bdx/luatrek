#!/usr/bin/env lua
--- Spaceship move, impulse and warp engine control
-- @module trek.move
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

-- @todo working on this code

--- Move Under Warp or Impulse Power
-- `Ramflag' is set if we are to be allowed to ram stars,
-- Klingons, etc.  This is passed from warp(), which gets it from
-- either play() or ram().  Course is the course (0 -> 360) at
-- which we want to move.  `Speed' is the speed we
-- want to go, and `p_time' is the expected time.  It
-- can get cut short if a long range tractor beam is to occur.  We
-- cut short the move so that the user doesn't get docked time and
-- energy for distance which he didn't travel.
--
-- We check the course through the current quadrant to see that he
-- doesn't run into anything.  After that, though, space sort of
-- bends around him.  Note that this puts us in the awkward posi-
-- tion of being able to be dropped into a sector which is com-
-- pletely surrounded by stars.  Oh Well.
--
-- If the SINS (Space Inertial Navigation System) is out, we ran-
-- domize the course accordingly before ever starting to move.
-- We will still move in a straight line.
--
-- Note that if your computer is out, you ram things anyway.  In
-- other words, if your computer and sins are both out, you're in
-- potentially very bad shape.
--
-- Klingons get a chance to zap you as you leave the quadrant.
-- By the way, they also try to follow you (heh heh).
--
-- Return value is the actual amount of time used.
-- @int ramflag if we are to be allowed to ram stars and etc.
-- @number course Course (0 to 360 degrees)
-- @number p_time Expected time
-- @number speed Speed we want to go
-- @treturn number actual amount of time used
function M.move (ramflag, course, p_time, speed)
    local ix = 0
    local iy = 0
    if V.Trace then
        printf("move: ramflag %d course %d time %.2f speed %.2f\n",
            ramflag, course, p_time, speed)
    end
    local sectsize = V.NSECTS
    -- initialize delta factors for move
    -- converted from degrees to radian (* pi / 180)
    local angle = course * 0.0174532925
    if not damaged("SINS") then
        angle = angle + Param.navigcrud[1] * (math.random() - 0.5)
    else
        if Ship.sinsbad then
            angle = angle + Param.navigcrud[0] * (math.random() - 0.5)
        end
    end
    local dx = -math.cos(angle)
    local dy = math.sin(angle)
    local bigger = math.abs(dx)
    local dist = math.abs(dy)
    if dist > bigger then
        bigger = dist
    end
    dx = dx / bigger
    dy = dy / bigger
    -- check for long range tractor beams
    -- @warning in bsdtrek move.c it says it's under debugging
    local evtime = Now.eventptr["E_LRTB"].date - Now.date
    if V.Trace then
        printf("E.evcode = %s, E.date = %.2f, evtime = %.2f\n",
            Now.eventptr["E_LRTB"].evcode,
            Now.eventptr["E_LRTB"].date, evtime)
    end
    if p_time > evtime and Etc.nkling < 3 then
        -- then we got a long range tractor beam
        evtime = evtime + 0.005
        p_time = evtime
    else
        evtime = -1.0e50
    end
    dist = p_time * speed
    -- move within quadrant
    Sect[Ship.sectx][Ship.secty] = "EMPTY"
    local x = Ship.sectx + 0.5
    local y = Ship.secty + 0.5
    local xn = V.NSECTS * dist * bigger
    local n = math.floor(xn + 0.5)
    if V.Trace then
        printf("dx = %.2f, dy = %.2f, xn = %.2f, n = %d\n", dx, dy, xn, n)
    end
    Move.free = false
    for i = 1, n do
        x = x + dx
        y = y + dy
        ix = math.floor(x)
        iy = math.floor(y)
        if V.Trace then
            printf("ix = %d, x = %.2f, iy = %d, y = %.2f\n", ix, x, iy, y)
        end
        if x < 1.0 or y < 1.0 or x > sectsize or y > sectsize then
            -- enter new quadrant
            dx = Ship.quadx * V.NSECTS + Ship.sectx + dx * xn
            dy = Ship.quady * V.NSECTS + Ship.secty + dy * xn
            if dx < 1 then
                ix = 0
            else
                ix = math.floor(dx + 0.5)
            end
            if dy < 1 then
                iy = 0
            else
                iy = math.floor(dy + 0.5)
            end
            if V.Trace then
                printf("New quad: ix = %d, iy = %d\n", ix, iy)
            end
            Ship.sectx = math.floor(x)
            Ship.secty = math.floor(y)
            trek.klingon.compkldist(0)
            Move.newquad = 2
            trek.klingon.attack(0)
            trek.score.checkcond()
            Ship.quadx = math.floor(ix / V.NSECTS)
            Ship.quady = math.floor(iy / V.NSECTS)
            Ship.sectx = ix % V.NSECTS
            Ship.secty = iy % V.NSECTS
            if ix < 1 or Ship.quadx > V.NQUADS or iy < 1 or Ship.quady > V.NQUADS then
                if not damaged("COMPUTER") then
                    -- @todo dumpme(0);
                else
                    trek.score.lose("L_NEGENB")
                end
            end
            trek.initquad.initquad(false)
            n = 0
            break
        end
        if Sect[ix][iy] ~= EMPTY then
            -- we just hit something
            if not damaged("COMPUTER") and ramflag <= 0 then
                ix = math.floor(x - dx)
                iy = math.floor(y - dy)
                printf("Computer reports navigation error; %s stopped at %d,%d\n",
                    Ship.shipname, ix, iy)
                Ship.energy = Ship.energy - (Param.stopengy * speed)
                break
            end
            -- test for a black hole
            if Sect[ix][iy] == "HOLE" then
                -- get dumped elsewhere in the galaxy
                -- @todo dumpme(1);
                trek.initquad.initquad()
                n = 0
                break
            end
            -- @todo ram(ix, iy);
            break
        end
    end
    if n > 0 then
        dx = Ship.sectx - ix
        dy = Ship.secty - iy
        dist = math.sqrt(dx * dx + dy * dy) / V.NSECTS
        p_time = dist / speed
        if evtime > p_time then
            -- spring the LRTB trap
            p_time = evtime
        end
        Ship.sectx = ix
        Ship.secty = iy
    end
    Sect[Ship.sectx][Ship.secty] = Ship.ship
    trek.klingon.compkldist(0)
    return p_time
end

--- Move under warp power
-- This is both the "move" and the "ram" commands, differing
-- only in the flag 'fl'.  It is also used for automatic
-- emergency override mode, when 'fl' is < 0 and 'c' and 'd'
-- are the course and distance to be moved.  If 'fl' >= 0,
-- the course and distance are asked of the captain.
--
-- The guts of this routine are in the routine move(), which
-- is shared with impulse().  Also, the working part of this
-- routine is very small; the rest is to handle the slight chance
-- that you may be moving at some riduculous speed.  In that
-- case, there is code to handle time warps, etc.
-- @int fl fl < 0: use given course and distance,
-- fl >= 0: course and distance are asked of the captain
-- @number c Course (0 to 360 degrees)
-- @number d Distance
function M.warp (fl, c, d)
    if Ship.cond == "DOCKED" then
        printf("%s is docked\n", Ship.shipname)
        return
    end
    if damaged("WARP") then
        trek.damage.out("WARP")
        return
    end
    local course = c
    local dist = d
    -- check to see that we are not using an absurd amount of power
    local power = (dist + 0.05) * Ship.warp3
    local percent = math.floor(100 * power / Ship.energy + 0.5)
    if percent >= 85 then
        printf("Scotty: That would consume %d%% of our remaining energy.\n",
            percent)
        if not trek.getpar.getynpar("Are you sure that is wise") then
            return
        end
    end
    -- compute the speed we will move at, and the time it will take
    local speed = Ship.warp2 / Param.warptime
    local p_time = dist / speed
    -- check to see that that value is not ridiculous
    percent = math.floor(100 * p_time / Now.time + 0.5)
    if percent >= 85 then
        printf("Spock: That would take %d%% of our remaining time.\n",
            percent)
        if not trek.getpar.getynpar("Are you sure that is wise") then
            return
        end
    end
    -- compute how far we will go if we get damages
    if Ship.warp > 6.0 and math.random(0,99) < (20 + (15 * (Ship.warp - 6.0))) then
        local frac = math.random
        dist = dist * frac
        p_time = p_time * frac
        trek.damage.damage("WARP", (frac + 1.0) * Ship.warp * (math.random() + 0.25) * 0.20)
    end
    -- do the move
    Move.time = M.move(fl, course, p_time, speed)
    -- see how far we actually went, and decrement energy appropriately
    dist = Move.time * speed
    local shldfactor
    if Ship.shldup then
        shldfactor = 2
    else
        shldfactor = 1
    end
    Ship.energy = Ship.energy - (dist * Ship.warp3 * shldfactor)
    -- test for bizarre events
    if Ship.warp <= 9.0 then
        return
    end
    printf("\n\n  ___ Speed exceeding warp nine ___\n\n")
    printf("Ship's safety systems malfunction\n")
    printf("Crew experiencing extreme sensory distortion\n")
    if math.random(0,99) >= (100 * dist) then
        printf("Equilibrium restored -- all systems normal\n")
        return
    end
    -- select a bizzare thing to happen to us
    percent = math.random(0,99)
    if percent < 70 then
        -- time warp
        if percent < 35 or not Game.snap then
            -- positive time warp
            p_time = (Ship.warp - 8.0) * dist * (math.random() + 1.0)
            Now.date = Now.date + p_time
            printf("Positive time portal entered -- it is now Stardate %.2f\n",
                Now.date)
            for i = 1, V.MAXEVENTS do
                local ev = Event[i].evcode;
                if ev == "E_FIXDV" or ev == "E_LRTB" then
                    Event[i].date = Event[i].date + p_time
                end
            end
            return
        end
        -- they got lucky: a negative time portal
        p_time = Now.date
        -- @todo s = Etc.snapshot
        -- @todo bmove(s, Quad, sizeof Quad);
        -- @todo bmove(s += sizeof Quad, Event, sizeof Event);
        -- @todo bmove(s += sizeof Event, &Now, sizeof Now);
        printf("Negative time portal entered -- it is now Stardate %.2f\n",
            Now.date)
        for i = 1, V.MAXEVENTS do
            if (Event[i].evcode == "E_FIXDV") then
                trek.schedule.reschedule(Event[i], Event[i].date - p_time)
            end
        end
        return
    end
    -- test for just a lot of damage
    if percent < 80 then
        trek.score.lose("L_TOOFAST")
    end
    printf("Equilibrium restored -- extreme damage occurred to ship systems\n");
    for k, v in pairs(Param.damfac) do
        damage(k, (3.0 * (math.random() + math.random()) + 1.0) * v)
    end
    Ship.shldup = false
end

--- dowarp() is used in a struct cvntab to call warp().  Since it is always ram
-- or move, fl is never < 0, so ask the user for course and distance, then pass
-- that to warp().
-- @int fl fl < 0: use given course and distance,
-- fl >= 0: course and distance are asked of the captain
function M.dowarp (fl)
    local status, c, d = trek.getpar.getcodi()
    if not status then
        return
    end
    M.warp(fl, c, d)
end

--- Set warp factor an by external input:
-- the warp factor is set for future move commands.  It is
-- checked for consistency.
function M.setwarp ()
    local warpfac=trek.getpar.getnumpar("Warp factor");
    if warpfac < 0.0 then
        return
    end
    if warpfac < 1.0 then
        printf("Minimum warp speed is 1.0\n")
        return
    end
    if warpfac > 10.0 then
        printf("Maximum speed is warp 10.0\n")
        return
    end
    if warpfac > 6.0 then
        printf("Damage to warp engines may occur above warp 6.0\n")
    end
    Ship.warp = warpfac
    Ship.warp2 = Ship.warp * warpfac
    Ship.warp3 = Ship.warp2 * warpfac
end

--- Move under impulse power
function M.impulse ()
	if Ship.cond == "DOCKED" then
		printf("Scotty: Sorry captain, but we are still docked.\n")
		return
    end
	if damaged("IMPULSE") then
		trek.damage.out("IMPULSE")
		return
    end
    local status, course, dist = trek.getpar.getcodi()
    if not status then
        return
    end
	power = math.floor(20 + 100 * dist)
	percent = math.floor(100 * power / Ship.energy + 0.5)
	if percent >= 85 then
		printf("Scotty: That would consume %d%% of our remaining energy.\n",
			percent)
		if not trek.getpar.getynpar("Are you sure that is wise") then
			return
        else
		    printf("Aye aye, sir\n")
        end
    end
	p_time = dist / 0.095
	percent = math.floor(100 * p_time / Now.time + 0.5)
	if percent >= 85 then
		printf("Spock: That would take %d%% of our remaining time.\n",
			percent);
		if not trek.getpar.getynpar("Are you sure that is wise") then
			return
        end
		printf("(The captain is finally gone mad)\n")
    end
	Move.time = move(0, course, p_time, 0.095)
	Ship.energy = Ship.energy - (20 + 100 * Move.time * 0.095)
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
