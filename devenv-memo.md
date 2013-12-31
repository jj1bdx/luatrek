# development environment memo

## Luarocks

* http://www.luarocks.org/
* Using Version 2.1.1
* On HomeBrew: `brew install luarocks --with-lua52`
* On FreeBSD: no Port, so use the following script:

        umask 022
        ./configure --lua-version=5.2 --lua-suffix=52 --with-lua-include=/usr/local/include/lua52 --with-lua-lib=/usr/local/lib --with-downloader=curl
        make build
        sudo zsh
        umask 022
        make install

## end of memorandum
