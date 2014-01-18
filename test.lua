#!/usr/bin/env lua

local trek = require "trek"
local V = trek.gstate

function string.ends(String,End)
    return End=='' or string.sub(String,-string.len(End))==End
end

test1="comp 10 20;"
test2="comp 10 20"
print(test1, string.ends(test1, ";"))
print(test2, string.ends(test2, ";"))

n, t = trek.getpar.getwords("test_prompt")
print("number of words=", n)
for i, v in ipairs(t) do
    print("t[", i, "]=", v)
end

print(trek.getpar.getynpar("Yes or no please"))

print(V.NSECTS)
print(V.Quad[1][1].bases)
V.Quad[1][1].bases = 1
print(V.Quad[1][1].bases)
