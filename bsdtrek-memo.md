# bsdtrek code reading memorandum

(Including how to implement bsdtrek functions with lua)

## Game variables and tables

* All defined in module trek.gstate
* Perform initialization check by Lua Penlight pl.strict.module()
* Convention: C NSECTS -> Lua V.NSECTS (where `local V = trek.gstate`)
* Even shorter names can be locally defined per each module

## Module names

* All modules are now under lua/trek/
* lua/trek/init.lua will load all the necessary modules
* Hierarchical naming: trek.getpar.getynpar()
* You can always assign shorthands in Lua, e.g., GP = trek.getpar; GP.getynpar()
* Module directory (`lua/trek/`) assignment is defined

## Random number functions

* C int ranf(int x) -> Lua math.random(0, x)
* C double franf(void) -> Lua math.random()
* C void srand(unsigned s) or void srandom(unsigned s) -> Lua math.randomseed(s)
* Do we need to use MT19937 in Luarocks lrandom package? Probably not.

## Things not in Lua

* Argument parsing of UI is ad-hoc; getpar.c defines word-by-word parsing functions, which are not suitable for Lua
    * C cgetc()/ungetc() function is not in Lua; we should reinvent an alternative, or discard them and acquire entire line at one by Lua `string = io.read("*l")` and parse the string by string:match(). C testnl(), readdelim(), and skiptonl() are simply too criptic and should be rewritten.
    * See getpar.getwords()
* Help for C getcodpar(): each acceptable command word should be displayed in the sorted manner
    * Abbreviation and full words are individually treated
    * Sort collation: per return value
    * Command cancellation patterns should be defined

* Do we need setjmp()/longjmp() just for restarting a game? I don't think so. The longjmp() calls are only used to notify end of the game and jump back to the main.c loop from lose() in lose.c, myreset() in play.c, and win() in win.c. Terminating the game altogether in the three cases will eliminate the need for the setjmp()/longjmp() pairs.
    * Removing the "Another Game" loop will be the simplest solution. 
    * Another solution is encapsulating the game process itself into a Lua protected environment/pcall() and catching the exception generated inside. This will prevent crashing the program with a subtle I/O error.

* Do we really need sleep() system calls? I don't think so. The sleep() calls are only used for game effects; they can be totally eliminated.

* C utility.c syserr("string") -> Lua error(string.format("LUATREK SYSERR: %s\n", "error string"))

* Array initialization in Lua needed -> Lua pl.array2d.new()

## end of memorandum
