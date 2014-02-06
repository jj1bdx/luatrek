#!/usr/bin/env lua

trek = require "trek"
local V = trek.gstate
trek.setup.setup()

for i = 1, V.NQUADS do
    for j = 1, V.NQUADS do
        local q = V.Quad[i][j]
        pl.utils.printf("Quad[%d][%d]: holes = %d, stars = %d, systemname = %d\n", i, j, 
            q.holes, q.stars, q.systemname)
    end
end
