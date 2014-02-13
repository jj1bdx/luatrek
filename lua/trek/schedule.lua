#!/usr/bin/env lua
--- Event schedule functions
-- @module trek.schedule
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

--- Schedule an event:
-- an event of type 'type' is scheduled for time NOW + 'offset'
-- into the first available slot.  'x', 'y', 'systemname',
-- 'hidden', 'ghost' are
-- considered the attributes for this event.
--
-- The address of the slot is returned.
-- @string type Event code string
-- @number offset date offset
-- @number x attribute coordinate X
-- @number y attribute coordinate Y
-- @param systemname attribute systemname)
-- @bool hidden attribute hidden
-- @bool ghost attribute ghost
-- @treturn Event itself
function M.schedule (type, offset, x, y, systemname, hidden, ghost)
    local date = Now.date + offset
    for i = 1, V.MAXEVENTS do
        local e = Event[i]
        if e.evcode == "" then
            -- got a slot
            if V.Trace then
                printf("schedule: type %s @ %.2f slot %d parm %d %d %s %s %s\n",
                    type, date, i, x, y, systemname, hidden, ghost)
            end
            e.evcode = type
            e.date = date
            e.x = x
            e.y = y
            e.systemname = systemname
            e.hidden = hidden
            e.ghost = ghost
            Now.eventptr[type] = e
            return e
        end
    end
    error(string.format("LUATREK SYSERR: Cannot schedule event %d parm %d %d %s %s %s",
           type, x, y, systemname, hidden, ghost))
    -- NOTREACHED
    return nil
end

--- Reschedule an event:
-- the event pointed to by 'e' is rescheduled to the current
-- time plus 'offset'.
-- @param e Event itself
-- @number offset date offset plus the current time
function M.reschedule (e, offset)
    local date = Now.date + offset
    e.date = date
    if V.Trace then
        printf("reschedule: type %s parm %d %d %s %s %s @ %.2f\n", 
                e.evcode, e.x, e.y, e.systemname, e.hidden, e.ghost, date)
    end
    return
end

--- Unschedule an event:
-- the event at slot 'e' is deleted.
-- @param e Event itself to be deleted from the slot
function M.unschedule (e)
    if V.Trace then
        printf("unschedule: type %s @ %.2f parm %d %d %s %s %s\n", 
                e.evcode, e.date, e.x, e.y, e.systemname, e.hidden, e.ghost)
    end
    local oldevcode = e.evcode
    Now.eventptr[oldevcode] = "NOEVENT"
    e.date = 1e50
    e.evcode = ""
    return
end

--- Abbreviated schedule function:
-- parameters are the event code and a factor for the time figure.
-- @string type Event code string
-- @number factor division factor
-- @number x attribute coordinate X
-- @number y attribute coordinate Y
-- @param systemname attribute systemname)
-- @bool hidden attribute hidden
-- @bool ghost attribute ghost
-- @treturn Event itself
function M.xsched (type, factor, x, y, systemname, hidden, ghost)
    return M.schedule(type, 
              Param.eventdly[type] * Param.time * (-1 * math.log(math.random() + 0.001)) / factor,
              x, y, systemname, hidden, ghost)
end

--- Simplified reschedule function:
-- parameters are the event itself and the division factor.
-- @param e Event itself 
-- @number factor division factor
function M.xresched (e, factor)
    return M.reschedule(e,
            Param.eventdly[e.evcode] * Param.time * (-1 * math.log(math.random() + 0.001)) / factor)
end

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
