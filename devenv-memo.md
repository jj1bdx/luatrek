# development environment memo

## Luatrek modules

* under `lua/trek/`

* Adding `lua/` into the search path is required as follows:

        # you can also do ". source-initenv.sh"
        export "LUA_PATH=$LUA_PATH;./lua/?.lua;./lua/?/init.lua"

## Luarocks

* http://www.luarocks.org/
* Using Version 2.1.2
* On HomeBrew: modify the distribution SHA1 checksum and `brew install luarocks --with-lua52`
* On FreeBSD: no Port, so use the following script:

        umask 022
        ./configure --lua-version=5.2 --with-lua=/usr/local --lua-suffix=52 --with-lua-include=/usr/local/include/lua52 --with-lua-lib=/usr/local/lib --with-downloader=curl
        make build
        sudo zsh
        umask 022
        make install

* Always use `--local` option for installing rocks for development
    * On OS X homebrew, the default installation is at /usr/local (site wide)

* Enable local rocks installation: add this to `~/.zshenv`

        eval `luarocks path`

## Other Luarocks modules for development

* Luatrek source code documentation will be with Ldoc
* Luatrek *will depend on* these modules
* Use `--local` option for installing rocks for development

* Penlight <http://stevedonovan.github.io/Penlight/api/index.html> Source: <https://github.com/stevedonovan/Penlight>

        luarocks --local install penlight

* LuaFileSystem <http://keplerproject.github.io/luafilesystem/> Source: <https://github.com/keplerproject/luafilesystem>

        # installed as a penlight dependency
        luarocks --local install luafilesystem

* Ldoc <http://stevedonovan.github.io/ldoc/> Source: <https://github.com/stevedonovan/LDoc>

        luarocks --local install ldoc

* Markdown <http://www.frykholm.se/files/markdown.lua>

        luarocks --local install markdown

## pathname of lua

* On OS X it's at `/usr/local/bin/lua`
* On FreeBSD it's at `/usr/local/bin` but the name is `lua52`
    * doing this will solve this issue: `ln -s /usr/local/bin/lua52 ~/bin/lua`
* by using the program name `lua`, `/usr/bin/env lua` will find the right path anyway (I hope)

## pathname of gcc on FreeBSD

* `gcc` no longer exists on FreeBSD 10 or later: make symlinks in a local bin directory

        ln -s /usr/local/bin/gcc46 ~/bin/gcc
        ln -s /usr/local/bin/g++46 ~/bin/g++

## Lua Documentation

* Use Ldoc to document the Lua modules

## end of memorandum
