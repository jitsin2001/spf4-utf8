\ 26.03.2007

\ Подключать, когда непонятно, в каком месте исключение происходит:

\ see also: throw-dump.f

: THROW_ORIG THROW ;
: THROW
  DUP 0=      IF THROW EXIT THEN
  DUP 10054 = IF THROW EXIT THEN
  DUP 10053 = IF THROW EXIT THEN
  DUP -1002 = IF THROW EXIT THEN

  \ R@ OVER DUMP-EXCEPTION-HEADER
  CR ." THREAD-ID: " THREAD-ID . ." STACK: " OK
  RP@
  BEGIN DUP R0 @ U> 0= WHILE
    STACK-ADDR.
    CELL+
  REPEAT
  DROP

  THROW
;

: ABORT
  -1 THROW
;
