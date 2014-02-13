#!/usr/bin/env lua

--- load trek as a global variable here
-- otherwise the program will not work!
trek = require "trek"
local V = trek.gstate
V.Trace = true
trek.setup.setup()
trek.play.play()
-- trek.play.main()

--[[
trek = require "trek"
local V = trek.gstate
trek.setup.setup()
trek.scan.srscan(-1)
trek.scan.lrscan()
trek.scan.visual()
trek.damage.dcrept()

for i = 1, V.Etc.nkling do
    local k = V.Etc.klingon[i]
    pl.utils.printf("Etc.klingon[%d]: x = %d, y = %d, power = %d, dist = %f\n",
    -- avgdist = %d, srndreq = %s\n",
                     i, k.x, k.y, k.power, k.dist)
                     --, k.avgdist, k.srndreq)
end
]]

--[[
for i = 1, V.NQUADS do
    for j = 1, V.NQUADS do
        local q = V.Quad[i][j]
        pl.utils.printf("Quad[%d][%d]: holes = %d, stars = %d, systemname = %d\n", i, j, 
            q.holes, q.stars, q.systemname)
    end
end
]]
