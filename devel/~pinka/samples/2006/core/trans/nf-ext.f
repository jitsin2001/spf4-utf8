\ 10.Feb.2006 Fri 20:44
\ Unobtrusive 'NotFound' Extension

: enqueueNOTFOUND ( xt -- )
\ добавить в конец списка трансляторов слова
\ транслятор, заданный xt
\ xt ( a u -- a u false | n*x true )

  S" NOTFOUND" SFIND 0= IF 2DROP 0 THEN
    WARNING @ >R WARNING 0!
  S" NOTFOUND" CREATED , ,
    R> WARNING !
  DOES> ( a u  a1 )
    DUP 2OVER 2>R >R
    @ DUP IF CATCH DUP 0= IF DROP RDROP RDROP RDROP EXIT THEN ( x x ior )
    DUP -2003 <>  OVER -321 <> AND  OVER -2011 <> AND  IF THROW THEN THEN ( x x ior|0 ) DROP
    \ see also: src/compiler/spf_translate.f # NOTFOUND
    ( x x ) 2DROP
    R> 2R> ROT CELL+ @ EXECUTE IF EXIT THEN
    -2003 THROW
;

\ example:
\ ' AsQName enqueueNOTFOUND
\ where AsQName stack notation
\   on STATE0 is ( i*x  a-text u-text -- j*x  true | i*x  a-text u-text false )
\   otherwise is ( a-text u-text -- true | a-text u-text false )


: preemptNOTFOUND ( xt -- )
\ добавить в начало списка трансляторов 'NOTFOUND'
\ транслятор, заданный xt
\ xt ( a u -- a u false | n*x true )

  S" NOTFOUND" SFIND 0= IF 2DROP 0 THEN
    WARNING @ >R WARNING 0!
  S" NOTFOUND" CREATED , ,
    R> WARNING !
  DOES> ( a u  a1 )
    DUP >R CELL+ @ EXECUTE IF RDROP EXIT THEN
    R> @ DUP IF EXECUTE EXIT THEN
    -2003 THROW
;
