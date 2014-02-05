#!/usr/bin/env lua
--- Luatrek game setup functions
-- @module trek.setup
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
local V = trek.gstate

--- Game length table
-- @table Lentab
-- @field s -> short
-- @field short Short game
-- @field m -> medium
-- @field medium Medium game
-- @field l -> long
-- @field long Long game
-- @field restart For restarting the game (Note: in bsdtrek it's NULL but the code compares NULL to 0 and that is BAD)
local M.Lentab = {
    ["s"] = 1, ["short"] = 1,
    ["m"] = 2, ["medium"] = 2,
    ["l"] = 4, ["long"] = 4,
    ["restart"] = -1,
}

--- Game skill table
-- @table Skitab
-- @field n -> novice
-- @field novice Novice
-- @field f -> fair
-- @field fair Fair
-- @field g -> good
-- @field good Good
-- @field e -> expert
-- @field expert Expert
-- @field c -> commodore
-- @field commodore Commodore
-- @field i -> impossible
-- @field impossible Impossible
local M.Skitab = {
    ["n"] = 1, ["novice"] = 1,
    ["f"] = 2, ["fair"] = 2,
    ["g"] = 3, ["good"] = 3,
    ["e"] = 4, ["expert"] = 4,
    ["c"] = 5, ["commodore"] = 5,
    ["i"] = 6, ["impossible"] = 6,
}

--- Global Game parameter
local Game = V.Game
--- Global Param parameter
local Param = V.Param
--- Global Ship parameter
local Ship = V.Ship

--- Setup Luatrek global variables
function M.setup ()
    local r = 0
    while r == 0 do
        r = trek.getpar.getcodpar("What length game", M.Lentab)
        if r < 0 then
            -- @todo check if restartgame() return a value
        end
    end -- loop breaks when r > 0
    Game.length = r
    Game.skill = trek.getpar.getcodpar("What skill game", M.Skitab)
    Game.tourn = false
    Game.passwd = trek.getpar.getstrpar("Enter tournament code")
    if Game.passwd == "tournament" then
        Game.tourn = true
        local d = 0
        for c in str:gmatch"." do
            d = bit32.lrotate(bit32.bxor(d, c), 1)
        end
        math.randomseed(d)
    end
    Param.bases = math.random(0, (6 - Game.skill)) + 2
    if Game.skill == 6 then
        Param.bases = 1
    end
    Now.bases = Param.bases
    Param.time = 6 * Game.length + 2
    Now.time = Param.time
    -- @todo more to go
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
