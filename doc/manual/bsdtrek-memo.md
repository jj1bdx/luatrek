# bsdtrek code reading memorandum

(Including how to implement bsdtrek functions with lua)

## Major lua difference from C

* Some bsdtrek code changes the for loop boundary expressions during the execution in the loop; this does not work in Lua since Lua only evaluate all the boundary expressions *only once* (Note also well about the loop variable scope of the for loop in Lua)
* Table/array indices begins with *ONE* (1) in Lua, while *ZERO*  (0) in C; This affects the most to the Quadrant and Sector coordinate systems and the distance calculation
* Note well on the variable scopes in Lua, which is vastly differenct from that in C
* Do not use `nil` or `false` as a boundary condition value of `repeat - until` loop in Lua

## Game variables and tables

* All global variables defined in module trek.gstate
* Perform initialization check by Lua Penlight pl.strict.module()
* Convention: C NSECTS -> Lua V.NSECTS (where `local V = trek.gstate`)
* Even shorter names can be locally defined per each module
* *Caution: shorthands for the functions in Lua must be defined as anonymous functions*

## Initialization and access to the tables

* Placeholder for table initialization must not be `nil` unless allowing the table to be deleted; a placeholder string will suffice
* Array/table initialization in Lua pl.array2d.new() and pl.tablex.new() with a table *must* be done with an anonymous function which returns the table, as this is the only way to pass the constructor to the Penlight functions
* Lua has no pointer and has only reference, so the access to each member element of C structures or Lua tables have to be performed by directly specifying the member (i.e., `c->member` must be rewritten to `c.member`)
* Comparing values between the two tables is non-trivial in Lua; curly braces are *constructors* -- use pl.tablex library functions
* Updating the contents of a table is non-trivial in Lua; use pl.tablex.update() (The source code is small BTW)

## Module names

* All modules are now under `lua/trek/`
* lua/trek/init.lua will load all the necessary modules
* Hierarchical naming: trek.getpar.getynpar()
* You can always assign shorthands in Lua, e.g., GP = trek.getpar; GP.getynpar()
* Module directory (`lua/trek/`) assignment is defined

## Random number functions

* C int ranf(int x) -> Lua math.random(0, (x - 1))
* C double franf(void) -> Lua math.random()
* C void srand(unsigned s) or void srandom(unsigned s) -> Lua math.randomseed(s)
* Do we need to use MT19937 in Luarocks lrandom package? Probably not.

## Argument parsing

* Argument parsing of UI is ad-hoc; getpar.c defines word-by-word parsing functions, which are not suitable for Lua
* C cgetc()/ungetc() function is not in Lua; we should reinvent an alternative, or discard them and acquire entire line at one by Lua `string = io.read("*l")` and parse the string by string:match(). C testnl(), readdelim(), and skiptonl() are simply too criptic and should be rewritten.
* Help for C getcodpar(): each acceptable command word should be displayed in the sorted manner; see Lua trek.getpar.getcodpar()
* Abbreviation and full words are individually treated
* Sort collation: per command word alphabetic sqeuence
* Command cancellation patterns should be defined

## Exception catch on the game main program

* Lua xpcall() with debug.traceback() is chosen for catching the general errors and game-ending exeptions

### Thoughts on exeption handling

* Do we need setjmp()/longjmp() just for restarting a game? I don't think so. The longjmp() calls are only used to notify end of the game and jump back to the main.c loop from lose() in lose.c, myreset() in play.c, and win() in win.c. Terminating the game altogether in the three cases will eliminate the need for the setjmp()/longjmp() pairs.
* Removing the "Another Game" loop will be the simplest solution. 
* Another solution is encapsulating the game process itself into a Lua protected environment/pcall() and catching the exception generated inside. This will prevent crashing the program with a subtle I/O error.
* Note well that catching an exception with pcall() will lose important information of the callback stack

## Formatted printing

* C utility.c syserr("string") -> Lua error(string.format("LUATREK SYSERR: %s\n", "error string"))
* C printf() -> Lua pl.utils.printf()
* Note well that in Lua string.format() and pl.utils.printf(), non-integer numbers cause errors when to be printed with `%d`; use `%f` in such a case
* More on Lua string.format() and pl.utils.printf(): non-number values cannot be printed with `%d` or `%f`; use `%s` to find out if the supposed-to-be-a-number variable is actually something different such as `nil`

## Other misc things

* Do we really need sleep() system calls? I don't think so. The sleep() calls are only used for game effects; they can be totally eliminated.
