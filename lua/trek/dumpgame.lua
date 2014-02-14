#!/usr/bin/env lua
--- Dump and restore the game intermediate into file
-- @module trek.dumpgame
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
--- shorthand for pl.utils.printf
local printf = pl.utils.printf
--- dumpgame version constant
local Dump_version = 2
--- dumpgame filename
local Dump_filename = "./luatrek.dump.txt"

--- Dump game:
-- this routine dumps the game onto the file `./luatrek.dump.txt`.  
-- The file contains a large Lua table text dump, which includes
-- the game version number and dump version number.
function M.dumpgame ()
    local status = pl.pretty.dump({ 
        ["Luatrek_version"] = V.Luatrek_version,
        ["Dump_version"] = Dump_version,
        ["Ship"] = V.Ship,
        ["Now"] = V.Now,
        ["Param"] = V.Param,
        ["Etc"] = V.Etc,
        ["Game"] = V.Game,
        ["Sect"] = V.Sect,
        ["Quad"] = V.Quad,
        ["Move"] = V.Move,
        ["Event"] = V.Event,
        },
        Dump_filename)
    if not status then
        error("LUATREK SYSERR: cannot dump\n")
    end
end

--- Restore game:
-- the game is restored from the file `./luatrek.dump.txt`.  In order for
-- this to succeed, the file must exist and be readable, must
-- have the correct Luatrek and Dump version numbers,
-- and must have all the appropriate table entries.
-- @treturn bool true for success, false for failure
function M.restartgame ()
    local table = pl.pretty.read(pl.utils.readfile(Dump_filename, false))
    if table.Luatrek_version ~= V.Luatrek_version or
        table.Dump_version ~= Dump_version then
        printf("restartgame: version number mismatch\n")
        return false
    end
    -- Version numbers ok, reload from the table 
    pl.tablex.update(V.Ship, table.Ship)
    pl.tablex.update(V.Now, table.Now)
    pl.tablex.update(V.Param, table.Param)
    pl.tablex.update(V.Etc, table.Etc)
    pl.tablex.update(V.Game, table.Game)
    pl.tablex.update(V.Sect, table.Sect)
    pl.tablex.update(V.Quad, table.Quad)
    pl.tablex.update(V.Move, table.Move)
    pl.tablex.update(V.Event, table.Event)
    return true
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
