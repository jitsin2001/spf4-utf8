( Обработка ошибок.
  Copyright [C] 1992-1999 A.Cherezov ac@forth.org
  Ревизия: Cентябрь 1999
)

VECT ERROR      \ обработчик ошибок (ABORT)
VECT (ABORT")
USER ER-A
USER ER-U

: LAST-WORD ( -> )
  CR TIB #TIB @ TYPE CR
  >IN @ 2- 0 MAX SPACES [CHAR] ^ EMIT SPACE
;
: ?ERROR ( F, N -> )
  SWAP IF THROW ELSE DROP THEN
;

: (ABORT1") ( flag c-addr -- )
  SWAP IF COUNT ER-U ! ER-A ! -2 THROW ELSE DROP THEN
;

