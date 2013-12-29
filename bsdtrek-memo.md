# bsdtrek code reading memorandum

## random number functions

* C int ranf(int x) -> lua math.random(0, x)
* C double franf(void) -> lua math.random()
* C void srand(unsigned s) or void srandom(unsigned s) -> lua math.randomseed(s)

## Things not in Lua

* cgetc()/ungetc() function is not in Lua; we should reinvent an alternative
* Do we need setjmp()/longjmp() just for restarting a game?
* Do we really need sleep() system calls? I don't think so.

## end of memorandum
