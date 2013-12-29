# bsdtrek code reading memorandum

## random number functions

* C int ranf(int x) -> lua math.random(0, x)
* C double franf(void) -> lua math.random()
* C void srand(unsigned s) or void srandom(unsigned s) -> lua math.randomseed(s)

## Things not in Lua

* cgetc()/ungetc() function is not in Lua; we should reinvent an alternative.
* Do we need setjmp()/longjmp() just for restarting a game? I don't think so. The longjmp() calls are only used to notify end of the game and jump back to the main.c loop from lose() in lose.c, myreset() in play.c, and win() in win.c. Terminating the game altogether in the three cases will eliminate the need for the setjmp()/longjmp() pairs. Removing the "Another Game" loop will be the simplest solution.
* Do we really need sleep() system calls? I don't think so. The sleep() calls are only used for game effects; they can be totally eliminated.

## end of memorandum
