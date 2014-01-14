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

local a = trek.utils.create2darray(4, 5, "elem")
a[1][1] = 1
a[2][2] = 2
a[3][3] = 3
a[4][4] = 4
for i, t1 in ipairs(a) do
    for j, v in ipairs(t1) do
        print("a[", i, "][", j, "]=", v)
    end
end

print(trek.const.Const.NSECTS)
