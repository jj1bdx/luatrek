#!/usr/bin/env lua
--- Photon Torpedo control
-- @module trek.torped
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

--- Randomize course:
-- This routine randomizes the course for torpedo number n.
-- Other things handled by this routine are misfires, damages
-- to the tubes, etc.
-- @int n number of torpedo
local function randcourse (n)
    local d = math.floor(((math.random() + math.random()) - 1.0) * 20)
    if math.abs(d) > 12 then
        printf("Photon tubes misfire")
        if n < 0 then
            printf("\n")
        else
            printf(" on torpedo %d\n", n)
        end
        if math.random() >= 0.5 then
            trek.damage.damage("TORPED", 
                                0.2 * math.abs(d) * (math.random() + 1.0))
        end
        d = math.floor(d * (1.0 + 2.0 * math.random()))
    end
    if Ship.shldup or Ship.cond == "DOCKED" then
        local r = Ship.shield
        r = 1.0 + (r / Param.shield)
        if Ship.cond == "DOCKED" then
            r = 2.0
        end
        d = math.floor(d * r)
    end
    return d
end

--- Photon Torpedo control
--
-- Either one or three photon torpedoes are fired.  If three
-- are fired, it is called a "burst" and you also specify
-- a spread angle.
--
-- Torpedoes are never 100% accurate.  There is always a random
-- cludge factor in their course which is increased if you have
-- your shields up.  Hence, you will find that they are more
-- accurate at close range.  However, they have the advantage that
-- at long range they don't lose any of their power as phasers
-- do, i.e., a hit is a hit is a hit, by any other name.
--
-- When the course spreads too much, you get a misfire, and the
-- course is randomized even more.  You also have the chance that
-- the misfire damages your torpedo tubes.
function M.torped ()
    if Ship.cloaked then
        printf("Federation regulations do not permit attack while cloaked.\n")
        return
    end
    if trek.damage.check_out("TORPED") then
        return
    end
    if Ship.torped <= 0 then
        printf("All photon torpedos expended\n")
        return
    end
    -- get the course
    local course = getnumpar("Torpedo course")
    if course < 0 or course > 360 then
        return
    end
    local burstmode = true
    -- need at least three torpedoes for a burst
    if Ship.torped < 3 then
        printf("Burst mode disabled, no burst mode selected\n");
        burstmode = false
    end
    if burstmode == true then
        burstmode = getynpar("Do you want a burst")
    end
    local burst
    if burstmode then
        burst = getnumpar("burst angle")
        if burst <= 0 then
            return
        end
        if burst > 15 then
            printf("Maximum burst angle is 15 degrees\n")
            return
        end
    end
    local sectsize = NSECTS
    local max = 1
    if burstmode then
        max = 3
        course = course - burst
    end
    for n = 1, max do
        -- select a nice random course
        local course2 = course + randcourse(n)
        local angle = course2 * math.pi / 180 -- convert to radians
        local dx = -math.cos(angle)
        local dy = math.sin(angle)
        local bigger = math.abs(dx)
        local x = math.abs(dy)
        if x > bigger then
            bigger = x
        end
        dx = dx / bigger
        dy = dy / bigger
        x = Ship.sectx + 0.5
        y = Ship.secty + 0.5
        if Ship.cond ~= "DOCKED" then
            Ship.torped = Ship.torped - 1
        end
        printf("Torpedo track")
        if n > 0 then
            printf(", torpedo number %d", n)
        end
        printf(":\n%6.1f %4.1f\n", x, y)
        while true do
            x = x + dx
            local ix = math.floor(x)
            y = y + dy
            local iy = math.floor(y)
            if x < 0.0 or x >= sectsize or
                y < 0.0 or y >= sectsize then
                printf("Torpedo missed\n")
                -- break the while loop
                break
            end
            printf("%6.1f %4.1f\n", x, y)
            local se = Sect[ix + 1][iy + 1]
            if se == "EMPTY" then
                -- do nothing
            elseif se == "HOLE" then
                printf("Torpedo disappears into a black hole\n")
                -- break the while loop
                break
            elseif se == "KLINGON" then
                for k = 1, Etc.nkling do
                    if Etc.klingon[k].x == ix or Etc.klingon[k].y == iy then
                        Etc.klingon[k].power = 
                            Etc.klingon[k].power - math.random(500, 1000)
                        if Etc.klingon[k].power > 0 then
                            printf("*** Hit on Klingon at %d,%d: extensive damages\n",
                                ix, iy)
                            -- break the for loop
                            break
                        end
                        -- klingon is hit dead
                        trek.kill.killk(ix, iy)
                        -- break the for loop
                        break
                    end
                end
            elseif se == "STAR" then
                trek.event.nova(ix, iy)
            elseif se == "INHABIT" then
                trek.kill.kills(ix, iy, -1)
            elseif se == "BASE" then
                trek.kill.killb(Ship.quadx, Ship.quady)
                Game.killb = Game.killb + 1
            else
                printf("Unknown object %s at %d,%d destroyed\n",
                    Sect[ix + 1][iy + 1], ix, iy)
                Sect[ix + 1][iy + 1] = "EMPTY"
            end
            -- break the while loop
            break
        end
        if damaged("TORPED") or Quad[Ship.quadx + 1][Ship.quady + 1].stars < 0 then
            -- break the for loop
            break
        end
        course = course + burst
    end
    Move.free = false
end


-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
