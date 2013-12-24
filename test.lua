#!/usr/bin/env lua
io.write("Hello? ")
io.flush()
x, y = io.read("*n", "*n")
io.write("x= ", x, " y= ", y, "\n")
