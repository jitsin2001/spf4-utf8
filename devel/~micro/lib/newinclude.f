: IsAnySlash ( c -- f )
\ f=TRUE, если c является слэшем (неважно каким)
  DUP [CHAR] \ = IF
    DROP TRUE
  ELSE
    [CHAR] / =
  THEN
;

: SelectPath  ( addr -- addr1 u )
\ вернуть путь (вместе со слэшем) из полного имени файла
\ addr - null-terminated полное имя
  DUP >R
  BEGIN
    DUP C@
  WHILE
    1+
  REPEAT
  R@ OVER = IF
    RDROP 0
  ELSE
    BEGIN
      DUP C@ IsAnySlash 0=
      OVER R@ = 0= AND
    WHILE
      1-
    REPEAT
    R> SWAP OVER -
    2DUP + C@ IsAnySlash IF 1+ THEN
  THEN
;

: SAVE-CURFILE ( addr u -- lastaddr )
\ записать addr u в CURFILE, и вернуть его старое значение
  CURFILE @ ROT ROT
  HEAP-COPY CURFILE !
;

: RESTORE-CURFILE ( lastaddr -- )
\ восстановить CURRFILE
  CURFILE @ FREE THROW
  CURFILE !
;

: INCLUDED-CURRPATH ( i*x addr u -- ior j*x )
\ addr u - полный путь или относительно текущей директории.
  2DUP
  SAVE-CURFILE >R
    INCLUDE-PROBE
  R> RESTORE-CURFILE
;

: MOVE-TO ( addr-src size addr-dst -- )
\ просто частовстречающаяся операция
  SWAP MOVE
;

: CONCAT-TO ( addr1 u1 addr2 u2 addr -- )
\ соединить строки addr1-u1 и addr2-u2, записать результат в addr
  >R
  2SWAP ( addr2 u2 addr1 u1 )
  SWAP OVER ( addr2 u2 u1 addr1 u1 )
  R@ MOVE-TO ( addr2 u2 u1 )
  R> + MOVE-TO
;

: CONCAT ( addr1 u1 addr2 u2 -- addr u )
\ соединить строки addr1-u1 и addr2-u2, вернуть динамически
\ выделенную область памяти с результатом. разультат -
\ null-terminaated
  2OVER NIP OVER + DUP >R 1+
  ALLOCATE THROW DUP >R
  CONCAT-TO
  R> R> 2DUP + 0 SWAP C!
;

: INCLUDED-LASTPATH ( i*x addr u -- ior j*x )
\ addr u - путь к файлу относительно пути к текущему интерпретируемому файлу
  CURFILE @ ?DUP IF
    SelectPath
    2SWAP CONCAT
    OVER >R
    INCLUDED-CURRPATH
    R> FREE THROW
  ELSE
    2DROP
    3
  THEN
;

: INCLUDED-SPF ( i*x addr u -- ior j*x )
\ addr u - путь к файлу относительно интерпретирующего его ехешника
  +ModuleDirName INCLUDED-CURRPATH
;

: INCLUDED ( i*x addr u -- j*x ) 
  2DUP INCLUDED-LASTPATH IF
    2DUP INCLUDED-SPF IF
      INCLUDED-CURRPATH THROW
    ELSE
      2DROP
    THEN
  ELSE
    2DROP
  THEN
;

S" ~ac/lib/require.f" INCLUDED

REQUIRE COMMENT> ~micro/lib/comment.f

COMMENT>

Добавление путей поиска в INCLUDED и REQUIRE
Если в файле \prj1\main.f интерпретируется INCLUDED, то пути поиска:
1. prj1\ (SPF3.75 по такому пути не ищет)
2. spf\ (от exeшника, если точнее)
3. Текущий
REQUIRE компилируется заново из ~ac/lib/require.f