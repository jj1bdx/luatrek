#!/usr/bin/env lua
--- Sensor scan functions
-- @module trek.scan
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
-- printf shorthand
local printf = pl.utils.printf

--- Short range sensor scanner:
-- a short range scan is taken of the current quadrant.  If the
-- flag `f` is one, it is an "auto srscan".  It does a status
-- report and a srscan.
-- If `f` is -1, you get a status report only.  If it is zero,
-- you get a srscan and an optional status report.  The status
-- report is taken if you enter "srscan yes"; for all srscans
-- thereafter you get a status report with your srscan until
-- you type "srscan no".  It defaults to on.
--
-- The current quadrant is filled in on the computer chart.
-- @int f 1 = auto srscan with status report, -1 = status report, 0 = srscan and optional status report
function M.srscan (f)
    if (f >= 0) and trek.damage.check_out("SRSCAN") then
        return
    end
    local statinfo = true
    if f > 0 then
        -- @todo Role of Etc.statreport?
        Etc.statreport = true
    end
    local q = Quad[Ship.quadx + 1][Ship.quady + 1]
    if f >= 0 then
        printf("\nShort range sensor scan\n")
        q.scanned = (q.klings * 100) + (q.bases * 10) + q.stars
        -- Sector coordinate value: 0 - 9
        printf("  ")
        for i = 0, V.NSECTS - 1 do
            printf("%d ", i)
        end
        printf("\n")
    end
    for i = 0, V.NSECTS - 1 do
        if f >= 0 then
            printf("%d ", i)
            for j = 0, V.NSECTS - 1 do
                printf("%s ", V.Sectdisp[Sect[i + 1][j + 1]])
            end
            printf("%d ", i)
            if statinfo then
                printf(" ")
            end
        end
        if statinfo then
            if i == 0 then
                printf("stardate      %.2f", Now.date)
            elseif i == 1 then
                printf("condition     %s", Ship.cond)
                if Ship.cloaked then
                    printf(", CLOAKED")
                end
            elseif i == 2 then
                printf("position      %d,%d/%d,%d",Ship.quadx, Ship.quady, Ship.sectx, Ship.secty)
            elseif i == 3 then
                printf("warp factor   %.1f", Ship.warp)
            elseif i == 4 then
                printf("total energy  %d", Ship.energy)
            elseif i == 5 then
                printf("torpedoes     %d", Ship.torped)
            elseif i == 6 then
                local s = "down"
                if Ship.shldup then
                    s = "up"
                end
                if trek.damage.damaged("SHIELD") then
                    s = "damaged"
                end
                printf("shields       %s, %d%%", s, 100.0 * Ship.shield / Param.shield)
            elseif i == 7 then
                printf("Klingons left %d", Now.klings)
            elseif i == 8 then
                printf("time left     %.2f", Now.time)
            elseif i == 9 then
                printf("life support  ")
                if trek.damage.damaged("LIFESUP") then
                    printf("damaged, reserves = %.2f", Ship.reserves)
                else 
                    printf("active")
                end
            end
        end
        printf("\n")
    end
    if f < 0 then
        printf("current crew  %d\n", Ship.crew)
        printf("brig space    %d\n", Ship.brigfree)
        printf("Klingon power %d\n", Param.klingpwr)
        local Lentab = {
            [1] = "short",
            [2] = "medium",
            [4] = "long",
        }
        local Skitab = {
            [1] = "novice",
            [2] = "fair",
            [3] = "good",
            [4] = "expert",
            [5] = "commodore",
            [6] = "impossible",
        }
        printf("Length, Skill %s, %s\n", Lentab[Game.length], Skitab[Game.skill])
        return
    end    
    -- Sector coordinate value: 0 - 9
    printf("  ")
    for i = 0, V.NSECTS - 1 do
        printf("%d ", i)
    end
    printf("\n")

    if q.distressed ~= 0 then
        printf("Distressed ")
    end
    if q.systemname > 0 then
        printf("Starsystem %s\n", V.Systemname[q.systemname]);
    end
end

--- Long range of scanners: 
-- a summary of the quadrants that surround you is printed.  The
-- hundreds digit is the number of Klingons in the quadrant,
-- the tens digit is the number of starbases, and the units digit
-- is the number of stars.  If the printout is "///" it means
-- that that quadrant is rendered uninhabitable by a supernova.
-- It also updates the "scanned" field of the quadrants it scans,
-- for future use by the "chart" option of the computer.
function M.lrscan ()
    if trek.damage.check_out("LRSCAN") then
        return
    end
    printf("Long range scan for quadrant %d,%d\n\n", Ship.quadx, Ship.quady)
    -- print the header on top
    -- left margin: three spaces
    printf("   ")
    for j = Ship.quady - 1, Ship.quady + 1 do
        -- six spaces per column
        if j < 0 or j > V.NQUADS - 1 then
            printf("      ")
        else
            printf("  %2d  ", j)
        end
    end
    -- scan the quadrants
    for i = Ship.quadx - 1, Ship.quadx + 1 do
        printf("\n   -------------------\n")
        if i < 0 or i > V.NQUADS - 1 then
            -- negative energy barrier
            printf("   !  *  !  *  !  *  !")
        else
            -- print the left hand margin
            printf("%2d !", i)
            for j = Ship.quady - 1, Ship.quady + 1 do
                if j < 0 or j > V.NQUADS - 1 then
                    -- negative energy barrier again
                    printf("  *  !")
                else 
                    local q = Quad[i + 1][j + 1]
                    if q.stars < 0 then
                        -- supernova
                        printf(" /// !")
                        q.scanned = 1000
                    else
                        q.scanned = q.klings * 100 + q.bases * 10 + q.stars
                        printf(" %3d !", q.scanned)
                    end
                end
            end
        end
    end
    printf("\n   -------------------\n")
    return
end

--- This table has the delta x, delta y for particular directions
-- @table Visdelta
-- @field tables_inside It contains all necessary direction info as the `{x, y}` table
local Visdelta = {
    { x = -1, y = -1 },
    { x = -1, y =  0 },
    { x = -1, y =  1 },
    { x =  0, y =  1 },
    { x =  1, y =  1 },
    { x =  1, y =  0 },
    { x =  1, y = -1 },
    { x =  0, y = -1 },
    { x = -1, y = -1 },
    { x = -1, y =  0 },
    { x = -1, y =  1 },
}

--- Visual scan:
-- a visual scan is made in a particular direction of three sectors
-- in the general direction specified.  This takes time, and
-- Klingons can attack you, so it should be done only when sensors
-- are out.
function M.visual ()
    local co = trek.getpar.getnumpar("direction")
    if co < 0 or co > 360 then
        return
    end
    local dir = math.floor((co + 22.5) / 45) + 1
    local v = Visdelta[dir]
    local ix = Ship.sectx + v.x
    local iy = Ship.secty + v.y
    local s
    if ix < 0 or ix > V.NSECTS - 1 or iy < 0  or iy > V.NSECTS - 1 then
        s = "?"
    else
        s = V.Sectdisp[Sect[ix + 1][iy + 1]]
    end
    printf("%d,%d %s ", ix, iy, s)
    v = Visdelta[dir + 1]
    ix = Ship.sectx + v.x
    iy = Ship.secty + v.y
    if ix < 0 or ix > V.NSECTS - 1 or iy < 0  or iy > V.NSECTS - 1 then
        s = "?"
    else
        s = V.Sectdisp[Sect[ix + 1][iy + 1]]
    end
    printf("%s ", s)
    v = Visdelta[dir + 2]
    ix = Ship.sectx + v.x
    iy = Ship.secty + v.y
    if ix < 0 or ix > V.NSECTS - 1 or iy < 0  or iy > V.NSECTS - 1 then
        s = "?"
    else
        s = V.Sectdisp[Sect[ix + 1][iy + 1]]
    end
    printf("%s %d,%d\n", s, ix, iy)
    Move.time = 0.05
    Move.free = false
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
