#!/usr/bin/env lua

trek = require "trek"
local V = trek.gstate
trek.setup.setup()
trek.damage.damage("LRSCAN", 0.1)
trek.scan.srscan(-1)
trek.damage.dcrept()

for i = 1, V.Etc.nkling do
    local k = V.Etc.klingon[i]
    pl.utils.printf("Etc.klingon[%d]: x = %d, y = %d, power = %d, dist = %f\n",
    -- avgdist = %d, srndreq = %s\n",
                     i, k.x, k.y, k.power, k.dist)
                     --, k.avgdist, k.srndreq)
end

--[[
for i = 1, V.NQUADS do
    for j = 1, V.NQUADS do
        local q = V.Quad[i][j]
        pl.utils.printf("Quad[%d][%d]: holes = %d, stars = %d, systemname = %d\n", i, j, 
            q.holes, q.stars, q.systemname)
    end
end
]]
