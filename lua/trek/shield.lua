#!/usr/bin/env lua
--- Luatrek spaceship shield and cloaking device control
-- @module trek.shield
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
local Device = V.Device
--- shorthand for Penlight printf
local printf = pl.utils.printf

--- Shield and cloaking device control
-- 'f' is one for auto shield up (in case of Condition RED),
-- zero for shield control, and negative one for cloaking
-- device control.
-- 
-- Called with an 'up' or 'down' on the same line, it puts
-- the shields/cloak into the specified mode.  Otherwise it
-- reports to the user the current mode, and asks if she wishes
-- to change.
--
-- This is not a free move.  Hits that occur as a result of
-- this move appear as though the shields are half up/down,
-- so you get partial hits.
-- @int f 1 for auto shield up, 0 for shield control, -1 for cloaking device control
function M.shield (f)
    local device, dev2, dev3, ind, stat, s
    local damaged = trek.damage.damaged
    if (f > 0) and (Ship.shldup or damaged("SRSCAN")) then
        return
    end
    if f < 0 then
        -- cloaking device
        if Ship.ship == "QUEENE" then
            printf("Ye Faire Queene does not have the cloaking device.\n")
            return
        end
        device = "Cloaking device"
        dev2 = "is"
        dev3 = "it"
        ind = "CLOAK"
        stat = Ship.cloaked
    else
        -- shields
        device = "Shields"
        dev2 = "are"
        dev3 = "them"
        ind = "SHIELD"
        stat = Ship.shldup
    end
    if damaged(ind) then
        if f <= 0 then
            trek.damage.out(ind)
        end
        return
    end
    if Ship.cond == "DOCKED" then
        printf("%s %s down while docked\n", device, dev2)
        return
    end
    if stat then
        s = string.format("%s %s up.  Do you want %s down", device, dev2, dev3)
    else
        s = string.format("%s %s down.  Do you want %s up", device, dev2, dev3)
    end
    if not trek.getpar.getynpar(s) then
        -- no device transition
        return
    end
    -- device state change
    stat = not stat
    -- display device status
    printf("%s %s ", device, dev2)
    if stat then
        printf("up\n")
    else
        printf("down\n")
    end
    -- device transition from down to up
    if stat then
        if f >= 0 then
            Ship.energy = Ship.energy - Param.shupengy
        else
            Ship.cloakgood = false
        end
    end
    Move.free = false
    if f >= 0 then
        Move.shldchg = true
    end
    -- save stat
    if f >= 0 then
        Ship.shldup = stat
    else
        Ship.cloaked = stat
    end
    return
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
