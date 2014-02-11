#!/usr/bin/env lua
--- Miscellaneous action handler including cruise computer control
-- @module trek.action
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

local Cputab = {
--- local table of commands and the specified functions
-- @table Cputab
-- @field command-names
    ["ch"] = 1, 
    ["chart"] = 1,
    ["t"] = 2, 
    ["trajectory"] = 2,
    ["c"] = {3, 0},
    ["course"] = {3, 0},
    ["m"] = {3, 1},
    ["move"] = {3, 1},
    ["s"] = 4,
    ["score"] = 4,
    ["p"] = 5,
    ["pheff"] = 5,
    ["w"] = 6,
    ["warpcost"] = 6,
    ["i"] = 7,
    ["impcost"] = 7,
    ["d"] = 8,
    ["distresslist"] = 8,
}

--- Course Calculation:
-- computes and outputs the course and distance from position
-- sqx,sqy/ssx,ssy to tqx,tqy/tsx,tsy, normalized to quadrant distance.
-- @int tqx target Quadrant coordinate X
-- @int tqy target Quadrant coordinate Y
-- @int tsx target Sector coordinate X
-- @int tsy target Sector coordinate Y
-- @treturn num Course
-- @treturn num Distance
function kalc (tqx, tqy, tsx, tsy)
    -- normalize to quadrant distances
    local quadsize = V.NSECTS
    -- note: quadrant range = 1 - 8, sector range = 1 - 10
    local dx = (Ship.quadx + ((Ship.sectx - 1) / quadsize)) -
                (tqx + ((tsx - 1) / quadsize))
    local dy = (Ship.quady + ((Ship.secty - 1) / quadsize)) -
                (tqy + ((tsy - 1) / quadsize))
    -- get the angle
    angle = math.atan2(dy, dx)
    -- make it 0 to 2 * pi
    if angle < 0.0 then
        angle = angle + (math.pi * 2)
    end
    -- convert from radians to degrees
    local course = math.floor(angle * (180 / pi) + 0.5)
    local dist = math.sqrt(dx * dx + dy * dy)
    return course, dist
end

static void
prkalc(int course, double dist)
{
    printf(": course %d  dist %.3f\n", course, dist);
}

--- On-Board Computer:
--
-- A computer request is fetched from the captain.  The requests
-- are:
--
-- chart -- print a star chart of the known galaxy.  This includes
--     every quadrant that has ever had a long range or
--     a short range scan done of it, plus the location of
--     all starbases.  This is of course updated by any sub-
--     space radio broadcasts (unless the radio is out).
--     The format is the same as that of a long range scan
--     except that ".1." indicates that a starbase exists
--     but we know nothing else.
--
-- trajectory -- gives the course and distance to every know
--     Klingon in the quadrant.  Obviously this fails if the
--     short range scanners are out.
--
-- course -- gives a course computation from whereever you are
--     to any specified location.  If the course begins
--     with a slash, the current quadrant is taken.
--     Otherwise the input is quadrant and sector coordi-
--     nates of the target sector.
--
-- move -- identical to course, except that the move is performed.
--
-- score -- prints out the current score.
--
-- pheff -- "PHaser EFFectiveness" at a given distance.  Tells
--     you how much stuff you need to make it work.
--
-- warpcost -- Gives you the cost in time and units to move for
--     a given distance under a given warp speed.
--
-- impcost -- Same for the impulse engines.
--
-- distresslist -- Gives a list of the currently known starsystems
--     or starbases which are distressed, together with their
--     quadrant coordinates.
function M.computer()
    if trek.damage.check_out("COMPUTER") then
        return
    end
    while true do
        local r = trek.getpar.getcodpar("Request", Cputab);
        if r == 1 then
            -- star chart
            printf("Computer record of galaxy for all long range sensor scans\n\n")
            printf("   ")
            -- print top header
            for i = 1, V.NQUADS do
                printf("-%2d- ", i)
            end
            printf("\n")
            for i = 1, V.NQUADS do
                printf("%2d ", i)
                for j = 1, V.NQUADS do
                    if i == Ship.quadx and j == Ship.quady then
                        printf("$$$  ")
                    else
                        local q = Quad[i][j]
                        -- 1000 or 1001 is special case
                        if q.scanned >= 1000 then
                            if q.scanned > 1000 then
                                printf(".1.  ")
                            else
                                printf("///  ")
                            end
                        else
                            if q.scanned < 0 then
                                printf("...  ")
                            else
                                printf("%3d  ", q.scanned)
                            end
                        end
                    end
                end
                printf("%2d\n", i)
            end
            printf("   ")
            -- print bottom footer
            for i = 1, V.NQUADS do
                printf("-%2d- ", i)
            end
            printf("\n");
        elseif r == 2 then
            -- trajectory
            if not trek.damage.check_out(SRSCAN) then
                if Etc.nkling <= 0 then
                    printf("No Klingons in this quadrant\n")
                else
                    -- for each Klingon, give the course & distance
                    for i = 1, Etc.nkling do
                        printf("Klingon at %d,%d", Etc.klingon[i].x, Etc.klingon[i].y)
                        course = kalc(Ship.quadx, Ship.quady, 
                                        Etc.klingon[i].x, Etc.klingon[i].y, &dist)
                        prkalc(course, dist)
                    end
                end
            end
        elseif r == {3, 0} or r == {3, 1} then
            -- course calculation
            local valid = false
            local num, tab = trek.getpar.getwords("Quadrant X, Y, Sector X, Y");
            if num ~= 4 then
                printf("Split four numbers by space\n")
            else
                local tqx = tonumber(tab[1])
                local tqy = tonumber(tab[2])
                local ix = tonumber(tab[3])
                local iy = tonumber(tab[4])
                if tqx == nil or tqy == nil or 
                   ix == nil or iy == nil then
                    printf("Invalid coordinate number entered\n")
                elseif tqx < 1 or tqx > V.NQUADS or
                   tqy < 1 or tqy > V.NQUADS or
                   ix < 1 or ix > V.NSECTS or
                   iy < 1 or iy > V.NSECTS then
                    printf("Coordinate out of range\n")
                end
                valid = true
            end
            if valid then
                local course, dist = kalc(tqx, tqy, ix, iy)
                if r[2] == 1 then
                    trek.move.warp(-1, course, dist)
                else
                    printf("%d,%d/%d,%d to %d,%d/%d,%d",
                        Ship.quadx, Ship.quady, Ship.sectx, Ship.secty, tqx, tqy, ix, iy)
                    prkalc(course, dist)
                end
            end
        elseif r == 4 then
            -- score
            trek.score.score()
        elseif r == 5 then
            -- phaser effectiveness
            local dist = trek.getpar.getnumpar("range")
            if dist >= 0 then
                dist = dist * 10.0
                local cost = math.floor(math.pow(0.90, dist) * 98.0 + 0.5)
                printf("Phasers are %d%% effective at that range\n", cost)
            end
        elseif r == 6 then
            -- warp cost (time/energy)
            local dist = trek.getpar.getnumpar("distance")
            if dist >= 0 then
                local warpfact = trek.getpar.getfltpar("warp factor")
                if warpfact <= 0.0 then
                    warpfact = Ship.warp
                end
                local cost = math.floor((dist + 0.05) * warpfact * warpfact * warpfact)
                local p_time = Param.warptime * dist / (warpfact * warpfact)
                printf("Warp %.2f distance %.2f cost %.2f stardates %d (%d w/ shlds up) units\n",
                    warpfact, dist, p_time, cost, cost + cost);
            end
        elseif r == 7 then
            -- impluse cost
            local dist = trek.getpar.getnumpar("distance")
            if dist >= 0 then
                local cost = math.floor(20 + 100 * dist)
                local p_time = dist / 0.095
                printf("Distance %.2f cost %.2f stardates %d units\n",
                    dist, p_time, cost)
            end
        elseif r == 8 then
            -- distresslist
            local distress = false
            printf("\n");
            /* scan the event list */
            for i = 1, V.MAXEVENTS do
                local e = Event[i]
                -- ignore hidden entries
                if not e.hidden then
                    if e.evcode == "E_KDESB" then
                        printf("Klingon is attacking starbase in quadrant %d,%d\n",
                            e.x, e.y)
                        distress = true
                    elseif e.evcode == "E_ENSLV" or 
                        e.evcode == "E_REPRO" then
                        printf("Starsystem %s in quadrant %d,%d is distressed\n",
                            V.Systemname[e.systemname], e.x, e.y)
                        distress = true
                    end
                end
            end
            if not distress then
                printf("No known distress calls are active\n")
            end
        end
    end
end

/*
**  Abandon Ship
**
-- The ship is abandoned.  If your current ship is the Faire
-- Queene, or if your shuttlecraft is dead, you're out of
-- luck.  You need the shuttlecraft in order for the captain
-- (that's you!!) to escape.
**
-- Your crew can beam to an inhabited starsystem in the
-- quadrant, if there is one and if the transporter is working.
-- If there is no inhabited starsystem, or if the transporter
-- is out, they are left to die in outer space.
**
-- These currently just count as regular deaths, but they
-- should count very heavily against you.
**
-- If there are no starbases left, you are captured by the
-- Klingons, who torture you mercilessly.  However, if there
-- is at least one starbase, you are returned to the
-- Federation in a prisoner of war exchange.  Of course, this
-- can't happen unless you have taken some prisoners.
**
-- Uses trace flag 40
*/

void
abandon(__unused int unused)
{
    struct quad    *q;
    int        i;
    int            j;
    struct event    *e;

    if (Ship.ship == QUEENE) {
        printf("You may not abandon ye Faire Queene\n");
        return;
    }
    if (Ship.cond != DOCKED)
    {
        if (damaged(SHUTTLE)) {
            out(SHUTTLE);
            return;
        }
        printf("Officers escape in shuttlecraft\n");
        /* decide on fate of crew */
        q = &Quad[Ship.quadx][Ship.quady];
        if (q->qsystemname == 0 || damaged(XPORTER))
        {
            printf("Entire crew of %d left to die in outer space\n",
                Ship.crew);
            Game.deaths += Ship.crew;
        }
        else
        {
            printf("Crew beams down to planet %s\n", systemname(q));
        }
    }
    /* see if you can be exchanged */
    if (Now.bases == 0 || Game.captives < 20 * Game.skill)
        lose(L_CAPTURED);
    /* re-outfit new ship */
    printf("You are hereby put in charge of an antiquated but still\n");
    printf("  functional ship, the Fairie Queene.\n");
    Ship.ship = QUEENE;
    Ship.shipname = "Fairie Queene";
    Param.energy = Ship.energy = 3000;
    Param.torped = Ship.torped = 6;
    Param.shield = Ship.shield = 1250;
    Ship.shldup = 0;
    Ship.cloaked = 0;
    Ship.warp = 5.0;
    Ship.warp2 = 25.0;
    Ship.warp3 = 125.0;
    Ship.cond = GREEN;
    /* clear out damages on old ship */
    for (i = 0; i < MAXEVENTS; i++)
    {
        e = &Event[i];
        if (e->evcode != E_FIXDV)
            continue;
        unschedule(e);
    }
    /* get rid of some devices and redistribute probabilities */
    i = Param.damprob[SHUTTLE] + Param.damprob[CLOAK];
    Param.damprob[SHUTTLE] = Param.damprob[CLOAK] = 0;
    while (i > 0)
        for (j = 0; j < NDEV; j++)
        {
            if (Param.damprob[j] != 0)
            {
                Param.damprob[j] += 1;
                i--;
                if (i <= 0)
                    break;
            }
        }
    /* pick a starbase to restart at */
    i = ranf(Now.bases);
    Ship.quadx = Now.base[i].x;
    Ship.quady = Now.base[i].y;
    /* setup that quadrant */
    while (1)
    {
        initquad(1);
        Sect[Ship.sectx][Ship.secty] = EMPTY;
        for (i = 0; i < 5; i++)
        {
            Ship.sectx = Etc.starbase.x + ranf(3) - 1;
            if (Ship.sectx < 0 || Ship.sectx >= NSECTS)
                continue;
            Ship.secty = Etc.starbase.y + ranf(3) - 1;
            if (Ship.secty < 0 || Ship.secty >= NSECTS)
                continue;
            if (Sect[Ship.sectx][Ship.secty] == EMPTY)
            {
                Sect[Ship.sectx][Ship.secty] = QUEENE;
                dock(0);
                compkldist(0);
                return;
            }
        }
    }
}

/*
**  Ask a Klingon To Surrender
**
-- (Fat chance)
**
-- The Subspace Radio is needed to ask a Klingon if he will kindly
-- surrender.  A random Klingon from the ones in the quadrant is
-- chosen.
**
-- The Klingon is requested to surrender.  The probability of this
-- is a function of that Klingon's remaining power, our power,
-- etc.
*/

void
capture(__unused int unused)
{
    int        i;
    struct kling    *k;
    double            x;

    /* check for not cloaked */
    if (Ship.cloaked)
    {
        printf("Ship-ship communications out when cloaked\n");
        return;
    }
    if (damaged(SSRADIO))
        return (out(SSRADIO));
    /* find out if there are any at all */
    if (Etc.nkling <= 0)
    {
        printf("Uhura: Getting no response, sir\n");
        return;
    }

    /* if there is more than one Klingon, find out which one */
    k = selectklingon();
    Move.free = 0;
    Move.time = 0.05;

    /* check out that Klingon */
    k->srndreq++;
    x = Param.klingpwr;
    x *= Ship.energy;
    x /= k->power * Etc.nkling;
    x *= Param.srndrprob;
    i = x;
#    ifdef xTRACE
    if (Trace)
        printf("Prob = %d (%.4f)\n", i, x);
#    endif
    if (i > ranf(100))
    {
        /* guess what, he surrendered!!! */
        printf("Klingon at %d,%d surrenders\n", k->x, k->y);
        i = ranf(Param.klingcrew);
        if ( i > 0 )
            printf("%d klingons commit suicide rather than be taken captive\n", Param.klingcrew - i);
        if (i > Ship.brigfree)
            i = Ship.brigfree;
        Ship.brigfree -= i;
        printf("%d captives taken\n", i);
        killk(k->x, k->y);
        return;
    }

    /* big surprise, he refuses to surrender */
    printf("Fat chance, captain\n");
    return;
}


/*
**  SELECT A KLINGON
**
-- Cruddy, just takes one at random.  Should ask the captain.
*/

static struct kling *
selectklingon(void)
{
    int        i;

    if (Etc.nkling < 2)
        i = 0;
    else
        i = ranf(Etc.nkling);
    return (&Etc.klingon[i]);
}

/*
**  call starbase for help
**
-- First, the closest starbase is selected.  If there is a
-- a starbase in your own quadrant, you are in good shape.
-- This distance takes quadrant distances into account only.
**
-- A magic number is computed based on the distance which acts
-- as the probability that you will be rematerialized.  You
-- get three tries.
**
-- When it is determined that you should be able to be remater-
-- ialized (i.e., when the probability thing mentioned above
-- comes up positive), you are put into that quadrant (anywhere).
-- Then, we try to see if there is a spot adjacent to the star-
-- base.  If not, you can't be rematerialized!!!  Otherwise,
-- it drops you there.  It only tries five times to find a spot
-- to drop you.  After that, it's your problem.
*/

const char    *Cntvect[3] =
{"first", "second", "third"};

void
help(__unused int unused)
{
    int        i;
    double            dist, x;
    int        dx, dy;
    int            j, l = 0;

    /* check to see if calling for help is reasonable ... */
    if (Ship.cond == DOCKED) {
        printf("Uhura: But Captain, we're already docked\n");
        return;
    }
    /* or possible */
    if (damaged(SSRADIO)) {
        out(SSRADIO);
        return;
    }
    if (Now.bases <= 0) {
        printf("Uhura: I'm not getting any response from starbase\n");
        return;
    }
    /* tut tut, there goes the score */
    Game.helps += 1;

    /* find the closest base */
    dist = 1e50;
    if (Quad[Ship.quadx][Ship.quady].bases <= 0)
    {
        /* there isn't one in this quadrant */
        for (i = 0; i < Now.bases; i++)
        {
            /* compute distance */
            dx = Now.base[i].x - Ship.quadx;
            dy = Now.base[i].y - Ship.quady;
            x = dx * dx + dy * dy;
            x = sqrt(x);

            /* see if better than what we already have */
            if (x < dist)
            {
                dist = x;
                l = i;
            }
        }

        /* go to that quadrant */
        Ship.quadx = Now.base[l].x;
        Ship.quady = Now.base[l].y;
        initquad(1);
    }
    else
    {
        dist = 0.0;
    }

    /* dematerialize the Enterprise */
    Sect[Ship.sectx][Ship.secty] = EMPTY;
    printf("Starbase in %d,%d responds\n", Ship.quadx, Ship.quady);

    /* this next thing acts as a probability that it will work */
    x = pow(1.0 - pow(0.94, dist), 0.3333333);

    /* attempt to rematerialize */
    for (i = 0; i < 3; i++)
    {
        sleep(2);
        printf("%s attempt to rematerialize ", Cntvect[i]);
        if (franf() > x)
        {
            /* ok, that's good.  let's see if we can set her down */
            for (j = 0; j < 5; j++)
            {
                dx = Etc.starbase.x + ranf(3) - 1;
                if (dx < 0 || dx >= NSECTS)
                    continue;
                dy = Etc.starbase.y + ranf(3) - 1;
                if (dy < 0 || dy >= NSECTS || Sect[dx][dy] != EMPTY)
                    continue;
                break;
            }
            if (j < 5)
            {
                /* found an empty spot */
                printf("succeeds\n");
                Ship.sectx = dx;
                Ship.secty = dy;
                Sect[dx][dy] = Ship.ship;
                dock(0);
                compkldist(0);
                return;
            }
            /* the starbase must have been surrounded */
        }
        printf("fails\n");
    }

    /* one, two, three strikes, you're out */
    lose(L_NOHELP);
}

-- End of module
return M

-- vim: set ts=4 sw=4 sts=4 et :
-- emacs: -*- mode:lua; tab-width:4; indent-tabs-mode:nil;  -*-
