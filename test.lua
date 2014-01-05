#!/usr/bin/env lua

getpar = require "getpar"

function string.ends(String,End)
    return End=='' or string.sub(String,-string.len(End))==End
end

test1="comp 10 20;"
test2="comp 10 20"
print(test1, string.ends(test1, ";"))
print(test2, string.ends(test2, ";"))

n, t = getpar.getwords("test_prompt")
print("number of words=", n)
local j = 0
for i, v in ipairs(t) do
    print("t[", i, "]=", v)
end

print(getpar.getynpar("Yes or no please"))
