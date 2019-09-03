REQUIRE /CHAR  ~pinka/samples/2005/ext/size.f 
REQUIRE [UNDEFINED] lib/include/tools.f

[UNDEFINED] CHAR- [IF]
: CHAR- /CHAR - ;
[THEN]

\ Строка как список, состоящий из первого элемента и остальных (хвоста).
\ HEAD -- голова, подстрока, состоящая из одного первого символа;
\ TAIL -- хвост, подстрока, состоящая из всех остальных символов, кроме первого.

( Здесь длина представляется в единицах адреса. Такой вот вариант. Должно быть, стоит исправить. )

: TAIL ( a u -- a1 u1 )
  DUP IF SWAP CHAR+ SWAP CHAR- EXIT THEN
  ( a 0 ) \ DROP 0
;
: HEAD ( a u -- a u1 )
  IF /CHAR EXIT THEN 0
;
: HEAD|TAIL ( a u -- a /char a2 u2 )
  2DUP HEAD 2SWAP TAIL
;
: HEAD|TAIL- ( a u -- a2 u2 a /char )
  2DUP TAIL 2SWAP HEAD
;
