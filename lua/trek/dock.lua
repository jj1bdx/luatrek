#!/usr/bin/env lua
--- Dock/undock to the starbase
-- @module trek.dock
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
--- Local trek.state shorthand
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

--- Dock to starbase:
-- the starship is docked to a starbase.  For this to work you
-- must be adjacent to a starbase.
--
-- You get your supplies replenished and your captives are
-- disembarked.  Note that your score is updated now, not when
-- you actually take the captives.
--
-- Any repairs that need to be done are rescheduled to take
-- place sooner.  This provides for the faster repairs when you
-- are docked.
function M.dock ()
    if Ship.cond == "DOCKED" then
        printf("Chekov: But captain, we are already docked\n")
        return
    end
    -- check for ok to dock, i.e., adjacent to a starbase
    local ok = false
    for i = Ship.sectx - 1, Ship.sectx + 1 do
        if i >= 0 and i <= V.NSECTS - 1 then
            for j = Ship.secty - 1, Ship.secty + 1 do
                if j >= 0 and j <= V.NSECTS - 1 and
                   Sect[i + 1][j + 1] == "BASE" then
                    ok = true
                    goto found
                end
            end
        end
    end
    ::found::
    if not ok then
        -- base not found
        printf("Chekov: But captain, we are not adjacent to a starbase.\n")
        return
    end
    -- restore resources
    Ship.energy = Param.energy
    Ship.torped = Param.torped
    Ship.shield = Param.shield
    Ship.crew = Param.crew
    Game.captives = Game.captives + (Param.brigfree - Ship.brigfree)
    Ship.brigfree = Param.brigfree
    -- reset ship's defenses
    Ship.shldup = false
    Ship.cloaked = false
    Ship.cond = "DOCKED"
    Ship.reserves = Param.reserves
    -- recalibrate space inertial navigation system
    Ship.sinsbad = false
    -- output any saved radio messages
    trek.event.dumpssradio()
    -- reschedule any device repairs
    for i = 1, V.MAXEVENTS do
        local e = Event[i]
        if e.evcode == "E_FIXDV" then
            trek.schedule.reschedule(e, (e.date - Now.date) * Param.dockfac)
        end
    end
    return
end

--- Leave a starbase:
-- this is the inverse of dock().  The main function it performs
-- is to reschedule any damages so that they will take longer.
function M.undock ()
    if Ship.cond ~= "DOCKED" then
        printf("Sulu: Pardon me captain, but we are not docked.\n")
        return
    end
    Ship.cond = "GREEN"
    Move.free = false
    -- reschedule device repair times (again)
    for i = 1, V.MAXEVENTS do
        local e = Event[i]
        if e.evcode == "E_FIXDV" then
            trek.schedule.reschedule(e, (e.date - Now.date) * Param.dockfac)
        end
    end
    return
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
