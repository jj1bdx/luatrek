#!/usr/bin/env lua
--- Ship damage control and report
-- @module trek.damage
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
--- Global Device table
local Device = V.Device
--- shorthand for Penlight printf
local printf = pl.utils.printf

--- Check for damaged devices:
-- this is a boolean function which returns true if the
-- specified device is broken.  It does this by checking the
-- event list for a "device fix" action on that device.
-- @string dev Device identifier string
-- @treturn bool true if broken, false if not
function M.damaged (dev)
    for i = 1, V.MAXEVENTS do
        local e = Event[i]
        if (e.evcode == "E_FIXDV") and (e.systemname == dev) then
            return true
        end
    end
    -- device fix not in event list -- device must not be broken
    return false
end

--- Check if a device is out:
-- the indicated device is checked to see if it is disabled.  If
-- it is, an attempt is made to use the starbase device.  If both
-- of these fails, it returns true (device is REALLY out),
-- otherwise it returns false(I can get to it somehow).
--
-- It prints appropriate messages too.
-- @string dev Device identifier string
-- @treturn bool true if really broken, false if available somehow
function M.check_out (dev)
    -- check for device ok
    if not M.damaged(dev) then
        return false
    end
    -- report it as being dead
    M.out(dev)
    -- but if we are docked, we can go ahead anyhow
    if Ship.cond ~= "DOCKED" then
        return true
    end
    printf("  Using starbase %s\n", Device[dev].name)
    return false
end

--- Announce device outage
-- @string dev Device identifier string
function M.out (dev)
    local d = Device[dev]
    printf("%s reports %s ", d.person, d.name)
    if string.match(d.name, "s$") then
        printf("are")
    else
        printf("is")
    end
    printf(" damaged\n")
end

--- Schedule Ship.damages to a Device:
-- device `dev` is damaged in an amount `dam`.  The damage is measured
-- in stardates, and is an additional amount of damage.  It should
-- be the amount to occur in non-docked mode.  The adjustment
-- to docked mode occurs automatically if we are docked.
--
-- Note that the repair of the device occurs on a DATE, meaning
-- that the dock() and undock() have to reschedule the event.
-- @string dev Device identifier string
-- @number dam damage amount
function M.damage (dev, dam)
    -- ignore zero damages
    if dam < 0 then
        return
    end
    printf("        %s damaged\n", Device[dev].name)
    -- find actual length till it will be fixed
    if Ship.cond == "DOCKED" then
        dam = dam * Param.dockfac
    end
    -- set the damage flag
    local f = M.damaged(dev)
    if not f then
        -- new damages -- schedule a fix
        trek.schedule.schedule("E_FIXDV", dam, 0, 0, dev, false, false)
        return
    end
    -- device already damaged -- add to existing damages
    -- scan for old damages
    for i = 1, V.MAXEVENTS do
        local e = Event[i]
        if (e.evcode == "E_FIXDV") and (e.systemname == dev) then
            -- got the right one; add on the new damages
            trek.schedule.reschedule(e, ((e.date - Now.date) + dam));
            return
        end
    end
    error(string.format("LUATREK SYSERR: Cannot find old damages %s\n", dev))
end

--- Damage control report:
-- print damages and time to fix.  This is taken from the event
-- list.  A couple of factors are set up, based on whether or not
-- we are docked.  (One of these factors will always be 1.0.)
-- The event list is then scanned for damage fix events, the
-- time until they occur is determined, and printed out.  The
-- magic number DAMFAC is used to tell how much faster you can
-- fix things if you are docked.
function M.dcrept ()
    -- set up the magic factors to output the time till fixed
    local m1, m2
    if Ship.cond == "DOCKED" then
        m1 = 1.0 / Param.dockfac
        m2 = 1.0
    else
        m1 = 1.0;
        m2 = Param.dockfac
    end
    printf("Damage control report:\n")
    local f = true
    -- scan for damages
    for i = 1, V.MAXEVENTS do
        local e = Event[i]
        if e.evcode == "E_FIXDV" then
            -- output the title first time
            if f then
                printf("%-24s  repair times\n", "")
                printf("%-24sin flight  docked\n", "device")
                f = false
            end
            -- compute time till fixed, then adjust by the magic factors
            local x = e.date - Now.date
            printf("%-24s%7.2f  %7.2f\n",
                Device[e.systemname].name, x * m1 + 0.005, x * m2 + 0.005)
            -- do a little consistancy checking
        end
    end
    -- if everything is ok, reassure the nervous captain
    if f then
        printf("All devices functional\n")
    end
end

--- Rest for repairs:
-- you sit around and wait for repairs to happen.  Actually, you
-- sit around and wait for anything to happen.  I do want to point
-- out however, that Klingons are not as patient as you are, and
-- they tend to attack you while you are resting.
--
-- You can never rest through a long range tractor beam.
--
-- In events() you will be given an opportunity to cancel the
-- rest period if anything momentous happens.
function M.rest ()
    -- get the time to rest
    local t = trek.getpar.getnumpar("How long")
    if t <= 0.0 then
        return
    end
    local percent = 100 * t / Now.time
    if percent >= 70.0 then
        printf("Spock: That would take %.2f%% of our remaining time.\n", percent)
        if not trek.getpar.getynpar("Are you really certain that is wise") then
            return
        end
    end
    Move.time = t
    -- boundary condition is the long range tractor beam
    t = Now.eventptr["E_LRTB"].date - Now.date
    if (Ship.cond ~= "DOCKED") and (Move.time > t) then
        Move.time = t + 0.0001
    end
    Move.free = false
    Move.resting = true
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
