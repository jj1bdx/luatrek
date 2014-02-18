#!/usr/bin/env lua
--- Luatrek main program to play the game
-- @module trek.play
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

--[[
-- This is the original credit of the BSD star trek in main.c:
/*
**     ####  #####    #    ####          #####  ####   #####  #   #
**    #        #     # #   #   #           #    #   #  #      #  #
**     ###     #    #####  ####            #    ####   ###    ###
**        #    #    #   #  #  #            #    #  #   #      #  #
**    ####     #    #   #  #   #           #    #   #  #####  #   #
**
**    C version by Eric P. Allman 5/76 (U.C. Berkeley) with help
**        from Jeff Poskanzer and Pete Rubinstein.
**
**    I also want to thank everyone here at Berkeley who
**    where crazy enough to play the undebugged game.  I want to
**    particularly thank Nick Whyte, who made considerable
**    suggestions regarding the content of the game.  Why, I'll
**    never forget the time he suggested the name for the
**    "capture" command.
**
**    Please send comments, questions, and suggestions about this
**        game to:
**            Eric P. Allman
**            Project INGRES
**            Electronics Research Laboratory
**            Cory Hall
**            University of California
**            Berkeley, California  94720
**
**    If you make ANY changes in the game, I sure would like to
**    know about them.  It is sort of an ongoing project for me,
**    and I very much want to put in any bug fixes and improvements
**    that you might come up with.
**
**    FORTRASH version by Kay R. Fisher (DEC) "and countless others".
**    That was adapted from the "original BASIC program" (ha!) by
**        Mike Mayfield (Centerline Engineering).
**
**    Additional inspiration taken from FORTRAN version by
**        David Matuszek and Paul Reynolds which runs on the CDC
**        7600 at Lawrence Berkeley Lab, maintained there by
**        Andy Davidson.  This version is also available at LLL
**        and at LMSC.  In all fairness, this version was the
**        major inspiration for this version of the game (trans-
**        lation:  I ripped off a whole lot of code).
**
**    Minor other input from the "Battelle Version 7A" by Joe Miller
**        (Graphics Systems Group, Battelle-Columbus Labs) and
**        Ross Pavlac (Systems Programmer, Battelle Memorial
**        Institute).  That version was written in December '74
**        and extensively modified June '75.  It was adapted
**        from the FTN version by Ron Williams of CDC Sunnyvale,
**        which was adapted from the Basic version distributed
**        by DEC.  It also had "neat stuff swiped" from T. T.
**        Terry and Jim Korp (University of Texas), Hicks (Penn
**        U.), and Rick Maus (Georgia Tech).  Unfortunately, it
**        was not as readable as it could have been and so the
**        translation effort was severely hampered.  None the
**        less, I got the idea of inhabited starsystems from this
**        version.
**
**    Permission is given for use, copying, and modification of
**        all or part of this program and related documentation,
**        provided that all reference to the authors are maintained.
**
**
**********************************************************************
*/
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

--- The Main program: call this function to start the game
function M.main()
    -- @todo No command option needed?
    printf("\nLuatrek version %s\n\n", V.Luatrek_version)
    -- Enable trace
    V.Trace = true
    local again = true
    while again do
        -- exception caught inside the xpcall
        local status, handler = xpcall(function ()
            -- play the game
            trek.setup.setup()
            M.play()
            end,
            -- error handler function
            function (err)
                if err.code == "ENDOFGAME" then
                    return false
                else
                    -- dump stacktrace then crash
                    return debug.traceback(err)
                end
            end)
        -- end-of-game handling
        if not status and not handler then
            -- end of game exception
            printf("\nLuatrek: game over\n")
            again = trek.getpar.getynpar("Another game")
        else
            -- status shouldn't be true because M.play() is an infinite loop
            -- so this should be a general error, crash it
            error(handler)
            -- NOTREACHED
        end
    end
    return
end

--- local function to quit the game
local function myreset ()
    error({code = "ENDOFGAME"})
end

--- local table of commands and the specified functions:
-- the table will return anonymous function as a value
-- @table Comtab
-- @field command-names
local Comtab =
{
    -- @todo functions commented out are all temporary
    ["abandon"] = function () trek.action.abandon() end,
    ["capture"] = function () trek.action.capture() end,
    ["cloak"] = function () trek.shield.shield(-1) end,
    ["c"] = function () trek.action.computer() end,
    ["computer"] = function () trek.action.computer() end,
    ["da"] = function () trek.damage.dcrept() end,
    ["damages"] = function () trek.damage.dcrept() end,
    ["destruct"] = function () trek.score.destruct() end,
    ["dock"] = function () trek.dock.dock() end,
    ["dump"] = function () trek.dumpgame.dumpgame() end,
    ["help"] = function () trek.action.help() end,
    ["i"] = function () trek.move.impulse() end,
    ["impulse"] = function () trek.move.impulse() end,
    ["l"] = function () trek.scan.lrscan() end,
    ["lrscan"] = function () trek.scan.lrscan() end,
    ["m"] = function () trek.move.dowarp(0) end,
    ["move"] = function () trek.move.dowarp(0) end,
    ["p"] = function () trek.phaser.phaser() end,
    ["phasers"] = function () trek.phaser.phaser() end,
    ["ram"] = function () trek.move.dowarp(1) end,
    ["rest"] = function () trek.damage.rest() end,
    ["s"] = function () trek.scan.srscan(0) end,
    ["srscan"] = function () trek.scan.srscan(0) end,
    ["sh"] = function () trek.shield.shield(0) end,
    ["shield"] = function () trek.shield.shield(0) end,
    ["st"] = function () trek.scan.srscan(-1) end,
    ["status"] = function () trek.scan.srscan(-1) end,
    ["terminate"] = function () myreset() end,
    ["t"] = function () trek.torped.torped() end,
    ["torpedo"] = function () trek.torped.torped() end,
    ["undock"] = function () trek.dock.undock() end,
    ["v"] = function () trek.scan.visual() end,
    ["visual"] = function () trek.scan.visual() end,
    ["w"] = function () trek.move.setwarp() end,
    ["warp"] = function () trek.move.setwarp() end,
};

--- Instruction read and main play loop:
-- well folks, this is it.  Here we have the guts of the game.
-- This routine executes moves.  It sets up per-move variables,
-- gets the command, and executes the command.  After the command,
-- it calls events() to use up time, attack() to have Klingons
-- attack if the move was not free, and checkcond() to check up
-- on how we are doing after the move.
function M.play ()
    while true do
        Move.free = true
        Move.time = 0.0
        Move.shldchg = false
        Move.newquad = "OLD"
        Move.resting = false
        -- the command table is defined in trek (init.lua)
        -- because all function calls must be defined
        -- *before* the Comtab elements are assigned
        local func = trek.getpar.getcodpar("Command", Comtab);
        func()
        trek.event.events(false)
        trek.klingon.attack(0)
        trek.score.checkcond()
    end
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
