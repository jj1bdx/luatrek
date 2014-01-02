#!/usr/bin/env lua

function string.ends(String,End)
    return End=='' or string.sub(String,-string.len(End))==End
end

test1="comp 10 20;"
test2="comp 10 20"
print(test1, string.ends(test1, ";"))
print(test2, string.ends(test2, ";"))

io.write("Hello? ")
io.flush()
x, y = io.read("*n", "*n")
io.write("x= ", x, " y= ", y, "\n")

