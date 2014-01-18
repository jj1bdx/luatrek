#!/usr/bin/env lua

trek = require "trek"

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

print(NSECTS)
print(Quad[1][1].bases)
Quad[1][1].bases = 1
print(Quad[1][1].bases)
