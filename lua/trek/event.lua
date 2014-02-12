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
            -- break the big while loop here
            break
        end
        -- otherwise one did.  Find out what it is
        if e.evcode == "E_SNOVA" then
            -- supernova
            -- cause the supernova to happen
            M.snova(-1, 0)
            -- and schedule the next one
            trek.schedule.xresched(e, 1)
        elseif e.evcode == "E_LRTB" then
            -- long range tractor beam
            -- schedule the next one
            trek.schedule.xresched(e, Now.klings)
            -- LRTB cannot occur if we are docked 
            if Ship.cond ~= "DOCKED" then
                -- pick a new quadrant
                local i = math.random(1, Now.klings)
                local ix, iy
                for jx = 0, V.NQUADS - 1 do
                    for jy = 0, V.NQUADS - 1 do
                        local q = Quad[jx + 1][jy + 1]
                        if q.stars >= 0 then
                            i = i - q.klings
                            if i <= 0 then
                                ix = jx
                                iy = jy
                                break
                            end
                        end
                    end
                    if i <= 0 then
                        break
                    end
                end
                -- test for LRTB to same quadrant
                if Ship.quadx ~= ix or Ship.quady ~= iy then
                    -- nope, dump the ship in the new quadrant
                    Ship.quadx = ix
                    Ship.quady = iy
                    printf("\n%s caught in long range tractor beam\n", Ship.shipname)
                    printf("*** Pulled to quadrant %d,%d\n", Ship.quadx, Ship.quady)
                    Ship.sectx = math.random(0, V.NSECTS - 1)
                    Ship.secty = math.random(0, V.NSECTS - 1)
                    trek.initquad.initquad(false)
                    -- truncate the move time
                    Move.time = xdate - idate
                end
            end
        elseif e.evcode == "E_KATSB" then
            -- Klingon attacks starbase
            -- if out of bases, forget it
            if Now.bases <= 0 then
                trek.schedule.unschedule(e)
            else 
                -- check for starbase and Klingons in same quadrant
                local same = false
                local ix, iy
                for i = 1, Now.bases do
                    ix = Now.base[i].x
                    iy = Now.base[i].y
                    -- see if a Klingon exists in this quadrant
                    local q = Quad[ix + 1][iy + 1]
                    local distressed = false
                    if q.klings > 0 then
                        -- see if already distressed
                        for j = 1, V.MAXEVENTS do
                            local e = Event[j]
                            if e.evcode == E_KDESB and
                               e.x == ix and e.y == iy then
                                distressed = true
                                -- break the for j loop
                                break
                            end
                        end
                    end
                    if not distressed then
                        -- got a potential attack
                        same = true
                        -- break the for i loop
                        break
                    end
                end
                -- put back the saved event
                e = ev
                if not same then
                    -- not now; wait a while and see if some Klingons move in
                    trek.schedule.reschedule(e, 0.5 + (3.0 * math.random()))
                else
                    -- schedule a new attack, and a destruction of the base
                    trek.schedule.xresched(e, 1)
                    e = trek.schedule.xsched("E_KDESB", 1, ix, iy, 0, false, false)
                    if not damaged("SSRADIO") then
                        printf("\nUhura:  Captain, we have received a distress signal\n")
                        printf("  from the starbase in quadrant %d,%d.\n", ix, iy)
                        restcancel = true
                    else
                        -- SSRADIO out, make it so we can't see the distress call
                        -- but it's still there!!!
                        e.hidden = true
                    end
                end
            end
        elseif e.evcode == "E_KDESB" then
            -- Klingon destroys starbase
            trek.schedule.unschedule(e)
            local q = Quad[e.x + 1][e.y + 1]
            -- if the base has mysteriously gone away, or if the Klingon
            -- got tired and went home, ignore this event
            if q.bases > 0 and q.klings > 0 then
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
        elseif e.evcode == "E_ISSUE" then
            -- issue a distress call
            trek.schedule.xresched(e, 1)
            -- if we already have too many, throw this one away
            if Ship.distressed < V.MAXDISTR then
                -- try a whole bunch of times to find something suitable
                local ix, iy, q
                local found = false
                for i = 1, 100 do
                    ix = math.random(0, V.NQUADS - 1)
                    iy = math.random(0, V.NQUADS - 1)
                    q = Quad[ix + 1][iy + 1]
                    -- need a quadrant which is not the current one,
                    -- which has some stars which are inhabited and
                    -- not already under attack, which is not
                    -- supernova'ed, and which has some Klingons in it
                    if (ix ~= Ship.quadx or iy ~= Ship.quady) and
                        q.stars >= 0 and q.distressed == false and
                        q.systemname ~= 0 and q.klings > 0 then
                        found = true
                        -- break the for loop
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
                            -- break the for loop
                            break
                        end
                    end
                end
                -- tell the captain about it if we can
                if not damaged("SSRADIO") then
                    printf("\nUhura: Captain, starsystem %s in quadrant %d,%d is under attack\n",
                        Systemname[e.systemname], ix, iy)
                    restcancel = true
                else
                    -- if we can't tell him, make it invisible
                    e.hidden = true
                end
            end
        elseif e.evcode == "E_ENSLV" then
            -- starsystem is enslaved
            trek.schedule.unschedule(e)
            -- see if current distress call still active
            local q = Quad[e.x + 1][e.y + 1]
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
                if not damaged("SSRADIO") then
                    printf("\nUhura:  We've lost contact with starsystem %s\n",
                        V.Systemname[e.systemname])
                    printf("  in quadrant %d,%d.\n", e.x, e.y)
                else
                    e.hidden = true
                end
            end
        elseif e.evcode == "E_REPRO" then
            --  Klingon reproduces
            -- see if distress call is still active
            local q = Quad[e.x + 1][e.y + 1]
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
                if (q.klings >= V.MAXKLQUAD) then
                    -- this quadrant is full and not ok, pick an adjacent one
                    for i = ix - 1, ix + 1 do
                        if i >= 0 and i <= V.NQUADS - 1 then
                            for j = iy - 1, iy + 1 do
                                if i >= 0 and i <= V.NQUADS - 1 then
                                    local q = Quad[i + 1][j + 1]
                                    -- check for this quad ok (not full & no snova)
                                    if q.klings < V.MAXKLQUAD and q.stars >= 0 then
                                        ok = true
                                        ix = i
                                        iy = j
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
                if ok then
                    -- deliver the child
                    q.klings = q.klings + 1
                    Now.klings = Now.klings + 1
                    if ix == Ship.quadx and iy == Ship.quady then
                        -- we must position Klingon
                        local six, siy = trek.initquad.sector()
                        Sect[six + 1][siy + 1] = "KLINGON"
                        local k = Etc.klingon[Etc.nkling]
                        k.x = six
                        k.y = siy
                        k.power = Param.klingpwr
                        k.srndreq = false
                        Etc.nkling = Etc.nkling + 1
                        trek.klingon.compkldist(Etc.klingon[0].dist == Etc.klingon[0].avgdist)
                    end
                    -- recompute time left
                    Now.time = Now.resource / Now.klings
                end
            end
        elseif e.evcode == "E_SNAP" then
            -- take a snapshot of the galaxy
            trek.schedule.xresched(e, 1)
            -- save a snapshot as a table
            Etc.snapshot = {
                ["Quad"] = pl.tablex.deepcopy(Quad),
                ["Event"] = pl.tablex.deepcopy(Event),
                ["Now"] = pl.tablex.deepcopy(Now),
            }
            Game.snap = 1
        elseif e.evcode == "E_ATTACK" then
            -- Klingons attack during rest period
            if not Move.resting then
                trek.schedule.unschedule(e)
            else 
                trek.klingon.attack(true)
                trek.schedule.reschedule(e, 0.5)
            end
        elseif e.evcode == "E_FIXDV" then
            -- de-damage the device
            local dev = e.systemname
            trek.schedule.unschedule(e)
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
    if e ~= "" and e ~= "NOEVENT" then
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
        if damaged("LIFESUP") and Ship.cond ~= "DOCKED" then
            Ship.reserves = Ship.reserves - Move.time
        end
    end
    return
end

--- output hidden distress calls
-- @treturn bool true if found any distressed or attacked starsystem
function M.dumpssradio ()
	local chkrest = false
	for j = 1, V.MAXEVENTS do
		local e = Event[j]
		-- if it is not hidden, then just ignore it
        -- if it's hidden and ghost, then unschedule it
		if e.hidden and e.ghost then
			trek.schedule.unschedule(e)
			printf("Starsystem %s in quadrant %d,%d is no longer distressed\n",
			        Quad[e.x + 1][e.y + 1].systemname, e.x, e.y)
            -- @todo do I need to clear the distressed flag?
        elseif e.evcode == "E_KDESB" then
			printf("Starbase in quadrant %d,%d is under attack\n", e.x, e.y)
			chkrest = true
        elseif e.evcode == "E_ENSLV" or e.evcode == "E_REPRO" then
			printf("Starsystem %s in quadrant %d,%d is distressed\n",
			        Quad[e.x + 1][e.y + 1].systemname, e.x, e.y)
			chkrest = true
        end
    end
	return chkrest
end

--- Cause a nova to occur:
-- a nova occurs.  It is the result of having a star hit with
-- a photon torpedo.  There are several things which may happen.
-- The star may not be affected.  It may go nova.  It may turn
-- into a black hole.  Any (yummy) it may go supernova.
--
-- Stars that go nova cause stars which surround them to undergo
-- the same probabilistic process.  Klingons next to them are
-- destroyed.  And if the starship is next to it, it gets zapped.
-- If the zap is too much, it gets destroyed.
-- @int x Sector coordinate X
-- @int y Sector coordinate Y
function M.nova (x, y)
    if Sect[x + 1][y + 1] ~= "STAR" or
        Quad[Ship.quadx + 1][Ship.quady + 1].stars < 0 then
        return
    end
    if math.random(0, 99) < 15 then
        printf("Spock: Star at %d,%d failed to nova.\n", x, y)
        return
    end
    if math.random(0, 99) < 5 then
        -- The star goes supernova
        return M.snova(x, y)
    end
    printf("Spock: Star at %d,%d gone nova\n", x, y)
    if math.random(0, 4) > 0 then
        -- 3 out of 4 it becomes just empty
        Sect[x + 1][y + 1] = "EMPTY"
    else
        -- 1 out of 4 it becomes a blackhole
        Sect[x + 1][y + 1] = "HOLE"
        Quad[Ship.quadx + 1][Ship.quady + 1].holes = 
            Quad[Ship.quadx + 1][Ship.quady + 1].holes + 1
    end
    Quad[Ship.quadx + 1][Ship.quady + 1].stars = 
        Quad[Ship.quadx + 1][Ship.quady + 1].stars - 1
    Game.kills = Game.kills + 1
    for i = x - 1, x + 1 do
        if i >= 0 and i <= V.NSECTS - 1 then
            for j = y - 1,  y + 1 do
                if j >= 0 and j <= V.NSECTS - 1 then
                    local se = Sect[i + 1][j + 1]
                    if se == "EMPTY" or se == "HOLE" then
                        -- do nothing
                    elseif se == "KLINGON" then
                        trek.kill.killk(i, j)
                    elseif se == "STAR" then
                        M.nova(i, j)
                    elseif se == "INHABIT" then
                        trek.kill.kills(i, j, -1)
                    elseif se == "BASE" then
                        trek.kill.killb(i, j)
                        Game.killb = Game.killb + 1
                    elseif se == "ENTERPRISE" or
                           se == "QUEENE" then
                        local sv = 2000
                        if Ship.shldup then
                            if Ship.shield >= sv then
                                Ship.shield = Ship.shield - sv
                                sv = 0
                            else
                                sv = sv - Ship.shield
                                Ship.shield = 0
                            end
                        end
                        Ship.energy = Ship.energy - sv
                        if Ship.energy <= 0 then
                            trek.score.lose("L_SUICID")
                        end
                    else
                        printf("Unknown object %s at %d,%d destroyed\n", se, i, j)
                        Sect[i + 1][j + 1] = "EMPTY"
                    end
                end
            end
        end
    end
    return
end

--- Cause supernova to occur:
-- a supernova occurs.  If ix < 0, a random quadrant is chosen;
-- otherwise, the current quadrant is taken, and (ix, iy) give
-- the sector quadrants of the star which is blowing up.
--
-- If the supernova turns out to be in the quadrant you are in,
-- you go into "emergency override mode", which tries to get you
-- out of the quadrant as fast as possible.  However, if you
-- don't have enough fuel, or if you by chance run into something,
-- or some such thing, you blow up anyway.  Oh yeh, if you are
-- within two sectors of the star, there is nothing that can
-- be done for you.
--
-- When a star has gone supernova, the quadrant becomes uninhab-
-- itable for the rest of eternity, i.e., the game.  If you ever
-- try stopping in such a quadrant, you will go into emergency
-- override mode.
-- @int x Sector coordinate X, if < 0 then randomly choose a quadrant
-- @int y Sector coordinate Y
function M.snova (x, y)
    local f = false
    local ix = x
    local iy = y
    local qx, qy, q
    if ix < 0 then
        -- choose a quadrant
        while true do
            qx = math.random(0, V.NQUADS - 1)
            qy = math.random(0, V.NQUADS - 1)
            q = Quad[qx + 1][qy + 1]
            if q.stars > 0 then
                -- break the while loop
                break
            end
        end
        -- if Ship locates on the same quadrant
        if Ship.quadx == qx and Ship.quady == qy then
            -- select a particular star
            local n = math.random(1, q.stars)
            for jx = 0, V.NSECTS - 1 do
                for jy = 0, V.NSECTS - 1 do
                    if Sect[jx + 1][jy + 1] == "STAR" or
                        Sect[ix + 1][iy + 1] == "INHABIT" then
                        n = n - 1
                        if n <= 0 then
                            ix = jx
                            iy = jy
                            -- break the for jy loop
                            break
                        end
                    end
                end
                if n <= 0 then
                    -- break the for jx loop
                    break
                end
            end
            f = true
        end
    else
        -- current quadrant
        qx = Ship.quadx
        qy = Ship.quady
        q = Quad[qx + 1][qy + 1]
        f = true
    end
    if f then
        -- supernova is in same quadrant as Enterprise
        printf("\n*** RED ALERT: supernova occurring at %d,%d ***\n", ix, iy)
        local dx = ix - Ship.sectx
        local dy = iy - Ship.secty
        if (dx * dx + dy * dy) <= 2 then
            -- if the distance <= sqrt(2), then the ship is killed
            printf("*** Emergency override attempt --- failed\n")
            trek.score.lose("L_SNOVA")
        end
        q.scanned = 1000
    else
        if not damaged("SSRADIO") then
            q.scanned = 1000
            printf("\nUhura: Captain, Starfleet Command reports a supernova\n")
            printf("  in quadrant %d,%d.  Caution is advised\n", qx, qy)
        end
    end
    -- clear out the supernova'ed quadrant
    Now.klings = Now.klings - q.klings
    if x >= 0 then
        -- Enterprise caused supernova
        Game.killk = Game.killk + q.klings
        Game.kills = Game.kills + q.stars
    end
    if q.bases then
        trek.kill.killb(qx, qy)
    end
    trek.kill.killd(qx, qy, (x >= 0))
    q.stars = -1
    q.klings = 0
    if Now.klings <= 0 then
        printf("Lucky devil, that supernova destroyed the last klingon\n")
        trek.score.win()
    end
    return
end

--- Automatic Override:
-- if we should be so unlucky as to be caught in a quadrant
-- with a supernova in it, this routine is called.  It is
-- called from checkcond().
--
-- It sets you to a random warp (guaranteed to be over 6.0)
-- and starts sending you off "somewhere" (whereever that is).
--
-- Please note that it is VERY important that you reset your
-- warp speed after the automatic override is called.  The new
-- warp factor does not stay in effect for just this routine.
--
-- This routine will never try to send you more than sqrt(2)
-- quadrants, since that is all that is needed.
function M.autover ()
    printf("*** ALERT:  The %s is in a supernova quadrant *** \n", Ship.shipname)
    printf("*** Emergency override attempts to hurl %s to safety\n", Ship.shipname)
    -- let's get out of here really now
    Ship.warp = 6.0 + (2.0 * math.random())
    Ship.warp2 = Ship.warp * Ship.warp
    Ship.warp3 = Ship.warp2 * Ship.warp
    local shldfactor
    if Ship.shldup then
        shldfactor = 2
    else
        shldfactor = 1
    end
    local dist = 0.75 * Ship.energy / (Ship.warp3 * shldfactor)
    local sqrt2 = math.sqrt(2)
    if dist > sqrt2 then
        dist = sqrt2
    end
    local course = math.random(0, 359)
    Etc.nkling = -1
    Ship.cond = "RED"
    trek.move.warp(-1, course, dist)
    trek.klingon.attack(false)
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
