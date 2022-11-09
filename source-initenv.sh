#!/bin/sh
eval "$(luarocks path --bin)"
export "LUA_PATH=$LUA_PATH;./lua/?.lua;./lua/?/init.lua"
