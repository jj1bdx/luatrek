#!/usr/bin/env lua
--- Event handler and time elapsing control
-- @module trek.event
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

CAUSE TIME TO ELAPSE

--- Cause time to elapse:
-- this routine does a hell of a lot.  It elapses time, eats up
-- energy, regenerates energy, processes any events that occur,
-- and so on.
-- @bool t_warp true if called in a time warp
function M.events (t_warp)
    -- if nothing happened, just allow for any Klingons killed
    if Move.time <= 0.0 then
        Now.time = Now.resource / Now.klings
        return
    end
    -- indicate that the cloaking device is now working
    Ship.cloakgood = true
    -- idate is the initial date
    local idate = Now.date;
    -- schedule attacks if resting too long
    if Move.time > 0.5 and  Move.resting then
        trek.schedule.schedule("E_ATTACK", 0.5, 0, 0, 0, false, false)
    end
    -- scan the event list
    while true do
        local restcancel = false
        local evnum = -1
        -- xdate is the date of the current event
        local xdate = idate + Move.time;
        -- find the first event that has happened
        local e, ev
        for i = 1, V.MAXEVENTS do
            e = Event[i]
            if e.evcode ~= "" and (not e.ghost) then
                if e.date < xdate then
                    xdate = e.date
                    ev = e
                    evnum = i
                end
            end
        end
        e = ev
        -- find the time between events
        local rtime = xdate - Now.date
        -- decrement the magic "Federation Resources" pseudo-variable
        Now.resource = Now.resource - (Now.klings * rtime)
        -- and recompute the time left
        Now.time = Now.resource / Now.klings
        -- move us up to the next date
        Now.date = xdate
        -- check for out of time
        if Now.time <= 0.0 then
            trek.score.lose("L_NOTIME")
        end
        if evnum >= 0 and V.Trace then
            printf("xdate = %.2f, evcode %s params %d %d %d\n",
                xdate, e.evcode, e.x, e.y, e.systemname)
        end
        -- if evnum < 0, no events occurred
        if evnum < 0 then
            break
        end
        -- otherwise one did.  Find out what it is
        if e.evcode == "E_SNOVA" then
            -- supernova
            -- cause the supernova to happen
            -- @todo snova(-1, 0);
            -- and schedule the next one
            trek.schedule.xresched(e, 1)
            break
        elseif e.evcode = "E_LRTB" then
            -- long range tractor beam
            -- schedule the next one
            trek.schedule.xresched(e, Now.klings)
            -- LRTB cannot occur if we are docked 
            if Ship.cond ~= "DOCKED" then
                -- pick a new quadrant
                local i = math.random(1, Now.klings)
                for ix = 1, V.NQUADS do
                    for iy = 1, V.NQUADS do
                        local q = Quad[ix][iy]
                        if q.stars >= 0 then
                            i = i - q.klings
                            if i <= 0 then
                                break
                            end
                        end
                    end
                    if i <= 0 then
                        break
                    end
                end
                -- test for LRTB to same quadrant
                if Ship.quadx == ix and Ship.quady == iy then
                    break
                end
                -- nope, dump the ship in the new quadrant
                Ship.quadx = ix
                Ship.quady = iy
                printf("\n%s caught in long range tractor beam\n", Ship.shipname)
                printf("*** Pulled to quadrant %d,%d\n", Ship.quadx, Ship.quady)
                Ship.sectx = math.random(1, V.NSECTS)
                Ship.secty = math.random(1, V.NSECTS)
                trek.initquad.initquad(false)
                -- truncate the move time
                Move.time = xdate - idate
            end
        elseif e.evcode = "E_KATSB" then
            -- Klingon attacks starbase
            -- if out of bases, forget it
            if Now.bases <= 0 then
                trek.schedule.unschedule(e)
                break
            end
            -- check for starbase and Klingons in same quadrant
            local same = false
            for i = 1, Now.bases do
                local ix = Now.base[i].x
                local iy = Now.base[i].y
                -- see if a Klingon exists in this quadrant
                local q = Quad[ix][iy]
                local distressed = false
                if q.klings > 0 then
                    -- see if already distressed
                    for j = 1, V.MAXEVENTS do
                        local e = Event[j]
                        if e.evcode == E_KDESB and
                           e.x == ix and e.y == iy then
                            distressed = true
                            break
                        end
                    end
                end
                if not distressed then
                    -- got a potential attack
                    same = true
                    break
                end
            end
            -- put back the saved event
            e = ev
            if not same then
                -- not now; wait a while and see if some Klingons move in
                trek.schedule.reschedule(e, 0.5 + (3.0 * math.random()))
                break
            end
            -- schedule a new attack, and a destruction of the base
            trek.schedule.xresched(e, 1)
            e = trek.schedule.xsched("E_KDESB", 1, ix, iy, 0, false, false)
            if not trek.damage.damaged("SSRADIO") then
                printf("\nUhura:  Captain, we have received a distress signal\n")
                printf("  from the starbase in quadrant %d,%d.\n", ix, iy)
                restcancel = true
            else
                -- SSRADIO out, make it so we can't see the distress call
                -- but it's still there!!!
                e.hidden = true
            end
        elseif e.evcode = "E_KDESB" then
            -- Klingon destroys starbase
            trek.schedule.unschedule(e)
            local q = Quad[e.x][e.y]
            -- if the base has mysteriously gone away, or if the Klingon
            -- got tired and went home, ignore this event
            if q->bases > 0 and q->klings > 0 then
                -- are we in the same quadrant?
                if e.x == Ship.quadx and e.y == Ship.quady then
                    -- yep, kill one in this quadrant */
                    printf("\nSpock: ")
                    trek.kill.killb(Ship.quadx, Ship.quady)
                else
                    -- kill one in some other quadrant
                    trek.kill.killb(e.x, e.y)
                end
            end
        elseif e.evcode = "E_ISSUE" then
            -- issue a distress call
            trek.schedule.xresched(e, 1)
            -- if we already have too many, throw this one away
            if Ship.distressed < V.MAXDISTR then
                -- try a whole bunch of times to find something suitable
                local ix, iy, q
                local found = false
                for i = 1, 100 do
                    ix = math.random(1, V.NQUADS)
                    iy = math.random(1, V.NQUADS)
                    q = Quad[ix][iy]
                    -- need a quadrant which is not the current one,
                    -- which has some stars which are inhabited and
                    -- not already under attack, which is not
                    -- supernova'ed, and which has some Klingons in it
                    if (ix ~= Ship.quadx or iy ~= Ship.quady) and
                        q.stars >= 0 and q.distressed = false and
                        q.systemname ~= 0 and q.klings > 0 then
                        found = true
                        break
                    end
                end
                if found then
                -- can't seem to find one; ignore this call
                -- got one!!  Schedule its enslavement
                    Ship.distressed = Ship.distressed + 1
                    e = xsched("E_ENSLV", 1, ix, iy, q.systemname, false, false)
                    for i = 1, V.MAXEVENTS do
                        if e == Event[i] then
                            q.distressed = i
                        end
                    end
                -- tell the captain about it if we can
                if not trek.damage.damaged("SSRADIO") then
                    printf("\nUhura: Captain, starsystem %s in quadrant %d,%d is under attack\n",
                        Systemname[e.systemname], ix, iy)
                    restcancel = true
                else
                    -- if we can't tell him, make it invisible
                    e.hidden = true
                end
            end
        elseif e.evcode = "E_ENSLV" then
            -- starsystem is enslaved
            trek.schedule.unschedule(e)
            -- see if current distress call still active
            local q = Quad[e.x][e.y]
            if q.klings <= 0 then
                -- no Klingons, clean up
                -- restore the system name
                q.systemname = e.systemname
                q.distressed = 0
            else
                -- if klingon is there
                -- play stork and schedule the first baby
                e = trek.schedule.schedule(
                    "E_REPRO", Param.eventdly["E_REPRO"] * math.random(), e.x, e.y, e.systemname,
                    e.distressed, e.ghost)
                -- report the disaster if we can
                if not trek.damage.damaged("SSRADIO") then
                    printf("\nUhura:  We've lost contact with starsystem %s\n",
                        V.Systemname[e.systemname])
                    printf("  in quadrant %d,%d.\n", e.x, e.y)
                else
                    e.hidden = true
                end
            end
        elseif e.evcode = "E_REPRO" then
            --  Klingon reproduces
            -- see if distress call is still active
            local q = Quad[e.x][e.y]
            if q.klings <= 0 then
                trek.schedule.unschedule(e)
                q.systemname = e.systemname
                q.distressed = 0
            else
                trek.schedule.xresched(e, 1)
                -- reproduce one Klingon
                local ix = e.x
                local iy = e.y
                local ok = false
                if (q.klings >= V.MAXKLQUAD)
                    -- this quadrant is full and not ok, pick an adjacent one
                    for i = ix - 1, ix + 1 do
                        if i >= 1 and i <= V.NQUADS then
                            for j = iy - 1, iy + 1 do
                                if i >= 1 and i <= V.NQUADS then
                                    local q = Quad[i][j]
                                    -- check for this quad ok (not full & no snova)
                                    if q->klings < MAXKLQUAD and q->stars >= 0 then
                                        ok = true
                                        ix = i
                                        iy = j
                                        break
                                    end
                                end
                            end
                        end
                    end
                if ok
                    -- deliver the child
                    q.klings = q.klings + 1
                    Now.klings = Now.klings + 1
                    if ix == Ship.quadx and iy == Ship.quady then
                        -- we must position Klingon
                        local six, siy = trek.initquad.sector()
                        Sect[six][siy] = "KLINGON"
                        local k = Etc.klingon[Etc.nkling]
                        k.x = six
                        k.y = siy
                        k.power = Param.klingpwr
                        k->srndreq = false
                        Etc.nkling = Etc.nkling + 1
                        trek.klingon.compkldist(Etc.klingon[0].dist == Etc.klingon[0].avgdist)
                    end
                    -- recompute time left
                    Now.time = Now.resource / Now.klings
                end
            end
        elseif e.evcode = "E_SNAP" then
            -- take a snapshot of the galaxy
            trek.schedule.xresched(e, 1)
            -- save a snapshot as a table
            Etc.snapshot = {
                quad = pl.tablex.deepcopy(Quad)
                event = pl.tablex.deepcopy(Event)
                now = pl.tablex.deepcopy(Now)
            }
            Game.snap = 1
        elseif e.evcode = "E_ATTACK" then
            -- Klingons attack during rest period
            if not Move.resting then
                trek.schedule.unschedule(e)
            else 
                trek.klingon.attack(true)
                trek.schedule.reschedule(e, 0.5)
        elseif e.evcode = "E_FIXDV" then
            -- fix a device
            local dev = e.systemname
            trek.schedule.unschedule(e)
            -- de-damage the device
            printf("%s reports repair work on the %s finished.\n",
                Device[dev].person, Device[dev].name)
            -- handle special processing upon fix
            if dev == "LIFESUP" then
                Ship.reserves = Param.reserves
            elseif dev == "SINS" then
                if Ship.cond ~= "DOCKED" then
                    printf("Spock has tried to recalibrate your Space Internal Navigation System,\n")
                    printf("  but he has no standard base to calibrate to.  Suggest you get\n")
                    printf("  to a starbase immediately so that you can properly recalibrate.\n")
                    Ship.sinsbad = 1
                end
            elseif dev == "SSRADIO" then
                -- restcancel = dumpssradio()
            end
        end
        -- ask canceling the rest period
        if restcancel and Move.resting and 
            trek.getpar.getynpar("Spock: Shall we cancel our rest period") then
            Move.time = xdate - idate
        end
    end
    -- unschedule an attack during a rest period
    local e = Now.eventptr["E_ATTACK"]
    if e ~= "" | e ~= "NOEVENT" then
        trek.schedule.unschedule(e)
    end
    if not t_warp then
        -- eat up energy if cloaked
        if Ship.cloaked then
            Ship.energy = Ship.energy - (Param.cloakenergy * Move.time)
        end
        -- regenerate resources
        local rtime = 1.0 - math.exp(-Param.regenfac * Move.time)
        Ship.shield = Ship.shield + ((Param.shield - Ship.shield) * rtime)
        Ship.energy = Ship.energy + ((Param.energy - Ship.energy) * rtime)
        -- decrement life support reserves
        if trek.damage.damaged("LIFESUP") and Ship.cond ~= "DOCKED" then
            Ship.reserves = Ship.reserves - Move.time
        end
    end
    return
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
