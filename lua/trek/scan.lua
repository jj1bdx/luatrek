#!/usr/bin/env lua
--- Short range sensor scan
-- @module trek.srscan
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

--- Short range sensor scanner
-- A short range scan is taken of the current quadrant.  If the
-- flag 'f' is one, it is an "auto srscan".  It does a status
-- report and a srscan.
-- If 'f' is -1, you get a status report only.  If it is zero,
-- you get a srscan and an optional status report.  The status
-- report is taken if you enter "srscan yes"; for all srscans
-- thereafter you get a status report with your srscan until
-- you type "srscan no".  It defaults to on.
--
-- The current quadrant is filled in on the computer chart.
-- @int f 1 = auto srscan with status report, -1 = status report, 0 = srscan and optional status report
function M.srscan (f)
    -- printf shorthand
    local printf = pl.utils.printf
    if (f >= 0) and trek.damage.check_out("SRSCAN") then
        return
    end
    local statinfo = false
    if f ~= 0 then
        statinfo = true
    else
        statinfo = trek.getpar.getynpar("status report")
        Etc.statreport = statinfo
    end
    if f > 0 then
        Etc.statreport = true
    end
    local q = Quad[Ship.quadx][Ship.quady]
    if f >= 0 then
        printf("\nShort range sensor scan\n")
        q.scanned = (q.klings * 100) + (q.bases * 10) + q.stars
        -- Sector coordinate value: 1 - 10, three letters needed
        printf("   ")
        for i = 1, V.NSECTS do
            printf("%-2d ", i)
        end
        printf("\n")
    end
    for i = 1, V.NSECTS do
        if f >= 0 then
            printf("%2d ", i)
            for j = 1, V.NSECTS do
                printf("%s  ", V.Sectdisp[Sect[i][j]])
            end
            printf("%2d", i)
            if statinfo then
                printf("   ")
            end
        end
        if statinfo then
            if i == 1 then
                printf("stardate      %.2f", Now.date)
            elseif i == 2 then
                printf("condition     %s", Ship.cond)
                if Ship.cloaked then
                    printf(", CLOAKED")
                end
            elseif i == 3 then
                printf("position      %d,%d/%d,%d",Ship.quadx, Ship.quady, Ship.sectx, Ship.secty)
            elseif i == 4 then
                printf("warp factor   %.1f", Ship.warp)
            elseif i == 5 then
                printf("total energy  %d", Ship.energy)
            elseif i == 6 then
                printf("torpedoes     %d", Ship.torped)
            elseif i == 7 then
                local s = "down"
                if Ship.shldup then
                    s = "up"
                end
                if trek.damage.damaged("SHIELD") then
                    s = "damaged"
                end
                printf("shields       %s, %d%%", s, 100.0 * Ship.shield / Param.shield)
            elseif i == 8 then
                printf("Klingons left %d", Now.klings)
            elseif i == 9 then
                printf("time left     %.2f", Now.time)
            elseif i == 10 then
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
    printf("   ")
    for i = 1, V.NSECTS do
        printf("%-2d ", i)
    end
    printf("\n")

    if q.distressed ~= 0 then
        printf("Distressed ")
    end
    if q.systemname > 0 then
        -- @todo fix to printf("Starsystem %s\n", systemname(q));
        printf("Starsystem %s\n", V.Systemname[q.systemname]);
    end
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
