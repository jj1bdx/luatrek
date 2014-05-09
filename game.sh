#!/bin/sh
/usr/bin/env LUA_PATH="$LUA_PATH;./lua/?.lua;./lua/?/init.lua" \
    lua -e 'trek = require "trek"; trek.play.main()'
