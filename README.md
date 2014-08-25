# Luatrek: Star Trek in Lua

* Current version: pre-0.2
* *Note well*: this repository is still in an early stage and buggy

## Background

This Star Trek game is a ported version of BSD (FreeBSD/DragonFly BSD) trek, written in C.

## Requirements

* Lua 5.2
* See `doc/manual/devenv-memo.md` for how to install the development environment

## How to run

* set `LUA_PATH` by `. ./source-initenv.sh`
* `./test.lua`
* Note: Trace mode is enabled; change variable `trek.gstate.Trace` to disable it

## Building documentation

    cd doc
    ldoc .
    # then open modules/index.html

## Bug reports

Use GitHub issue to report the bugs

## TODO

* Revision after release of Lua 5.3: integer type handling
* Revision keeping up with LuaRocks 2.2.0

## Author

* Kenji Rikitake

## License

* See `LICENSE` for the license (BSD 3-clause)
* The `license` command in the game will show you the license too
