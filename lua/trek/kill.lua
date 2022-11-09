#!/usr/bin/env lua
--- Processing killed entities: this module handles the killing off of almost anything
-- @module trek.kill
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

--- Handle a Klingon's death
-- the Klingon at the sector given by the parameters is killed
-- and removed from the Klingon list.  Notice that it is not
-- removed from the event list; this is done later, when the
-- the event is to be caught.  Also, the time left is recomputed,
-- and the game is won if that was the last klingon.
-- @int ix Klingon's Sector X coordinate
-- @int iy Klingon's Sector Y coordinate
function M.killk (ix, iy)
    printf("   *** Klingon at %d,%d destroyed ***\n", ix, iy)
    -- remove the scoundrel
    Now.klings = Now.klings - 1
    Sect[ix + 1][iy + 1] = "EMPTY"
    Quad[Ship.quadx + 1][Ship.quady + 1].klings = 
        Quad[Ship.quadx + 1][Ship.quady + 1].klings - 1
    Quad[Ship.quadx + 1][Ship.quady + 1].scanned = 
        Quad[Ship.quadx + 1][Ship.quady + 1].scanned - 100
    Game.killk = Game.killk + 1
    -- find the Klingon in the Klingon list
    for i = 1, Etc.nkling do
        if ix == Etc.klingon[i].x and iy == Etc.klingon[i].y then
            -- purge him from the list
            Etc.nkling = Etc.nkling - 1
            for j = i, Etc.nkling do
                Etc.klingon[j] = Etc.klingon[j + 1]
            end
            -- break the for i loop
            break
        end
    end
    -- find out if that was the last one
    if Now.klings <= 0 then
        trek.score.win()
    end
    -- recompute time left
    Now.time = Now.resource / Now.klings
    return
end

--- Handle a starbase's death
-- @int qx Klingon's Quadrant X coordinate
-- @int qy Klingon's Quadrant Y coordinate
function M.killb (qx, qy)
    local q = Quad[qx + 1][qy + 1]
    if q.bases <= 0 then
        return
    end
    if not trek.damage.damaged("SSRADIO") then
        -- then update starchart
        if q.scanned < 1000 then
            q.scanned = q.scanned - 10
        else
            if q.scanned > 1000 then
                q.scanned = -1
            end
        end
    end
    q.bases = 0
    for i = 1, Now.bases do
        if qx == Now.base[i].x and qy == Now.base[i].y then
            -- purge the base from the list
            Now.bases = Now.bases - 1
            for j = i, Now.bases do
                Now.bases[j] = Now.bases[j + 1]
            end
            -- break the for loop
            break
        end
    end
    if qx == Ship.quadx and qy == Ship.quady then
        Sect[Etc.starbase.x + 1][Etc.starbase.y + 1] = "EMPTY"
        if Ship.cond == "DOCKED" then
            trek.dock.undock()
        end
        printf("Starbase at %d,%d destroyed\n", Etc.starbase.x, Etc.starbase.y)
    else
        if not trek.damage.damaged("SSRADIO") then
            printf("Uhura: Starfleet command reports that the starbase in\n")
            printf("   quadrant %d,%d has been destroyed\n", qx, qy)
        else
            schedule("E_KATSB", 1e50, qx, qy, 0, false, true)
        end
    end
end

-- Kill an inhabited starsystem
-- @int x when f == 0, Quadrant X coordinate: else Sector X coordinate
-- @int y when f == 0, Quadrant Y coordinate: else Sector Y coordinate
-- @int f f ~= 0: this quadrant, f < 0: Entreprise's fault
function M.kills (x, y, f)
    -- current quadrant
    local q = Quad[Ship.quadx + 1][Ship.quady + 1]
    if f ~= 0 then
        Sect[x + 1][y + 1] = "EMPTY"
        local name = q.systemname
        if name == 0 then
            return
        end
        printf("Inhabited starsystem %s at %d,%d destroyed\n",
                V.Systemname[name], x, y);
        if f < 0 then
            Game.killinhab = Game.killinhab + 1;
        end
    else 
        -- f == 0: different quadrant
        q = Quad[x + 1][y + 1]
    end
    if q.distressed then
        -- distressed starsystem
        local e = Event[q.distressed]
        printf("Distress call for %s invalidated\n",
            V.Systemname[e.systemname])
        trek.schedule.unschedule(e)
    end
    q.systemname = 0
    q.stars = q.stara - 1
end

-- "Kill" a distress call
-- @int x when f == 0, Quadrant X coordinate
-- @int y when f == 0, Quadrant Y coordinate
-- @bool f true if user is to be informed
function M.killd (x, y, f)
    local q = Quad[x + 1][y + 1]
    for i = 1, V.MAXEVENTS do
        local e = Event[i]
        if e.x == x and e.y == y then
            if e.evcode == "E_KDESB" then
                if f then
                    printf("Distress call for starbase in %d,%d nullified\n", x, y)
                    trek.schedule.unschedule(e)
                end
            elseif e.evcode == "E_ENSLV" or e.evcode == "E_REPRO" then
                if f then
                    printf("Distress call for %s in quadrant %d,%d nullified\n",
                            V.Systemname[e.systemname], x, y)
                    q.systemname = e.systemname
                    trek.schedule.unschedule(e)
                else
                    e.ghost = true
                end
            end
        end    
    end
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
