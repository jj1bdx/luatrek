#!/usr/bin/env lua
--- Scoring and game win/lose termination decision
-- @module trek.score
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
--- Game.skill value to skill word conversion table
local Skitab = {
    [1] = "novice",
    [2] = "fair",
    [3] = "good",
    [4] = "expert",
    [5] = "commodore",
    [6] = "impossible",
}

--- Calculate and print out the current game score
-- @treturn number current score
function M.score ()
    printf("\n*** Your score:\n")
    local u = Game.killk
    local t = Param.klingpwr
    local s = t / 4 * u
    if t ~= 0 then
        printf("%d Klingons killed --> %d\n", u, t)
    end
    local r = Now.date - Param.date
    if r < 1.0 then
        r = 1.0
    end
    r = Game.killk / r
    t = 400 * r
    s = s + t
    if t ~= 0 then
        printf("Kill rate %.2f Klingons/stardate --> %d\n", r, t)
    end
    r = Now.klings
    r = r / (Game.killk + 1)
    t = -400 * r
    s = s + t
    if t ~= 0 then
        printf("Penalty for %d klingons remaining --> %d\n", Now.klings, t)
    end
    if Move.endgame > 0 then
        u = Game.skill
        t = 100 * u
        s = s + t
        printf("Bonus for winning a %s game --> %d\n", Skitab[u], t)
    end
    if Game.killed then
        s = s - 500
        printf("Penalty for getting killed --> -500\n")
    end
    u = Game.killb
    t = -100 * u
    s = s + t
    if t ~= 0 then
        printf("%d starbases killed --> %d\n", u, t)
    end
    u = Game.helps
    t = -100 * u
    s = s + t
    if t ~= 0 then
        printf("%d calls for help --> %d\n", u, t)
    end
    u = Game.kills
    t = -5 * u
    s = s + t
    if t ~= 0 then
        printf("%d stars destroyed --> %d\n", u, t)
    end
    u = Game.killinhab
    t = -150 * u
    s = s + t
    if t ~= 0 then
        printf("%d inhabited starsystems destroyed --> %d\n", u, t)
    end
    if Ship.ship ~= "ENTERPRISE" then
        s = s - 200
        printf("penalty for abandoning ship --> -200\n")
    end
    u = Game.captives
    t = 3 * u
    s = s + t
    if t ~= 0 then
        printf("%d Klingons captured --> %d\n", u, t)
    end
    u = Game.deaths
    t = -1 * u
    s = s + t
    if t ~= 0 then
        printf("%d casualties --> %d\n", u, t)
    end
    printf("\n***  TOTAL --> %d\n", s)
    return s
end

--- Signal game won:
-- this routine prints out the win message, arranges to print out
-- your score, tells you if you have a promotion coming to you.
-- This function generates an error() exception with
-- code "ENDOFGAME".
--
-- Pretty straightforward, although the promotion algorithm is
-- pretty off the wall.
function M.win ()
    printf("\nCongratulations, you have saved the Federation\n")
    Move.endgame = 1
    -- print and return the score
    local s = M.score()
    -- decide if she gets a promotion
    if (Game.helps == 0 and
        Game.killb == 0 and
        Game.killinhab == 0 and
        ((5 * Game.kills) + Game.deaths) < 100 and
        s >= 1000 and
        Ship.ship == "ENTERPRISE") then
        printf("In fact, you are promoted one step in rank,\n")
        if Game.skill >= 6 then
            printf("to the exalted rank of Commodore Emeritus\n")
        else
            printf("from %s to %s",
                   Skitab[Game.skill], Skitab[Game.skill + 1])
        end
    end
    error({code = "ENDOFGAME"})
end

--- Print out loser messages:
-- the messages are printed out, the score is computed and
-- printed, and the game is restarted.  Oh yeh, any special
-- actions which need be taken are taken.
-- This function generates an error() exception with
-- code "ENDOFGAME".
-- @string why Lose reason code
function M.lose (why)
    Game.killed = true
    printf("\n%s\n", V.Losemsg[why])
    if why == "L_NOTIME" then
        Game.killed = false
    end
    Move.endgame = -1
    M.score()
    error({code = "ENDOFGAME"})
end

--- Check for condition after a move:
-- various ship conditions are checked.  First we check
-- to see if we have already lost the game, due to running
-- out of life support reserves, running out of energy,
-- or running out of crew members.  The check for running
-- out of time is in events().
-- 
-- If we are in automatic override mode (Etc.nkling < 0), we
-- don't want to do anything else, lest we call autover
-- recursively.
-- 
-- In the normal case, if there is a supernova, we call
-- autover() to help us escape.  If after calling autover()
-- we are still in the grips of a supernova, we get burnt
-- up.
-- 
-- If there are no Klingons in this quadrant, we nullify any
-- distress calls which might exist.
-- 
-- We then set the condition code, based on the energy level
-- and battle conditions.
function M.checkcond()
    -- see if we are still alive and well
    if Ship.reserves < 0.0 then
        M.lose("L_NOLIFE")
    end
    if Ship.energy <= 0 then
        M.lose("L_NOENGY")
    end
    if Ship.crew <= 0 then
        M.lose("L_NOCREW")
    end
    -- if in auto override mode, ignore the rest
    if Etc.nkling < 0 then
        return
    end
    -- call in automatic override if appropriate
    if Quad[Ship.quadx + 1][Ship.quady + 1].stars < 0 then
        trek.event.autover()
    end
    -- if hitting supernova again then the ship is killed
    if Quad[Ship.quadx + 1][Ship.quady + 1].stars < 0 then
        M.lose("L_SNOVA")
    end
    -- nullify distress call if appropriate
    if Etc.nkling <= 0 then
        trek.kill.killd(Ship.quadx, Ship.quady, true)
    end
    -- set condition code
    if Ship.cond == "DOCKED" then
        return
    end
    if Etc.nkling > 0 then
        Ship.cond = "RED"
        return
    end
    if Ship.energy < Param.energylow then
        Ship.cond = "YELLOW"
        return
    end
    Ship.cond = "GREEN"
    return
end

--- Self Destruct Sequence:
-- the computer starts up the self destruct sequence.  Obviously,
-- if the computer is out nothing can happen.  You get a countdown
-- and a request for password.  This must match the password that
-- you entered at the start of the game.
--
-- You get to destroy things when you blow up; hence, it is
-- possible to win the game by destructing if you take the last
-- Klingon with you.
--
-- Note: the effects of sleep()ing and the control characters of
-- the original bsdtrek are all removed.
function M.destruct ()
    -- You cannot self-destroy when computer is damaged
    if trek.damage.damaged("COMPUTER") then
        trek.damage.out("COMPUTER")
        return
    end
    printf("***** Entering into the self destruct sequence *****\n")
    local checkpass = trek.getpar.getstrpar("Enter password verification")
    if checkpass ~= Game.passwd then
        printf("Self destruct sequence aborted\n")
        return
    end
    printf("Password verified; self destruct sequence continues:\n")
    printf("***** %s destroyed *****\n", Ship.shipname)
    Game.killed = true
    -- let's see what we can blow up!!!!
    local zap = 20.0 * Ship.energy
    Game.deaths = Game.deaths + Ship.crew
    for i = 1, Etc.nkling do
        if Etc.klingon[i].power * Etc.klingon[i].dist <= zap then
            trek.kill.killk(Etc.klingon[i].x, Etc.klingon[i].y)
            i = i - 1 -- @todo is this OK?
        end
    end
    -- if we didn't kill the last Klingon (detected by killk),
    -- then we lose....
    M.lose("L_DSTRCT")
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
