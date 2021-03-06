( Поддержка основных типов данных BNF. Удобно применять для реализации
  на Форте трансляторов с других языков, для которых существует формальное
  описание синтаксиса на BNF.
  Andrey Cherezov, 26.Mar.2000
)

REQUIRE {         lib/ext/locals.f
REQUIRE COMPARE-U ~ac/lib/string/compare-u.f
REQUIRE STR@      ~ac/lib/str5.f

USER Look \ будем заглядывать вперед на один символ

: GetNextChar ( -- )
  GetChar IF Look ! ELSE DROP 13 Look ! THEN   \ 13=CR - трактуется как конец строки
  >IN 1+!
;

: Expected ( addr u -- )
  ER-U ! ER-A ! -2 THROW \ i.e. ABORT"
;

: Match ( char -- )
  { char \ c }
  Look @ -> c
  char c =
  IF GetNextChar ELSE c char " Expected char:'{n}' instead of '{n}'" STR@ Expected THEN
;

\ --------------------------------------------------------------------
\ В комментариях к слову приводится BNF-описание синтаксиса

\ digit_nz        ::= "1" / "2" / "3" / "4" / "5" / "6" / "7" / "8" / "9"

: IsDigit_nz ( char -- flag )
  DUP [CHAR] 9 > IF DROP FALSE EXIT THEN
  [CHAR] 0 >
;

\ digit           ::= "0" / digit_nz

: IsDigit ( char -- flag )
  DUP IsDigit_nz SWAP [CHAR] 0 = OR
;

\ number          ::= 1*digit
\                     ;; Unsigned 32-bit integer
\                     ;; (0 <= n < 4,294,967,296)

: GetNumber ( -- s )
  { \ s }
  "" -> s
  Look @ IsDigit 0= IF S" digit" Expected THEN
  BEGIN
    Look @ IsDigit
  WHILE
    Look 1 s STR+
    GetNextChar
  REPEAT
  s
;

\ nz_number       ::= digit_nz *digit
\                     ;; Non-zero unsigned 32-bit integer
\                     ;; (0 < n < 4,294,967,296)

: GetNzNumber ( -- s )
  { \ s }
  "" -> s
  Look @ IsDigit_nz 0= IF S" digit_nz" Expected THEN
  BEGIN
    Look @ IsDigit
  WHILE
    Look 1 s STR+
    GetNextChar
  REPEAT
  s
;

\ CHAR            ::= <any 7-bit US-ASCII character except NUL,
\                      0x01 - 0x7f>

: IsCHAR ( char -- flag )
  DUP 1 < IF DROP FALSE EXIT THEN
      127 > IF      FALSE EXIT THEN
  TRUE
;

\ TEXT_CHAR       ::= <any CHAR except CR and LF>

: IsTEXT_CHAR ( char -- flag )
  DUP 13 = IF DROP FALSE EXIT THEN
  DUP 10 = IF DROP FALSE EXIT THEN
  IsCHAR
;

\ CHAR8           ::= <any 8-bit octet except NUL, 0x01 - 0xff>
: IsCHAR8 ( char -- flag )
  DUP 255 > IF DROP FALSE THEN
  0 >
;

\ CTL             ::= <any ASCII control character and DEL,
\                         0x00 - 0x1f, 0x7f>
: IsCTL ( char -- flag )
  DUP 127 = IF DROP TRUE EXIT THEN
  DUP 31 >  IF DROP FALSE EXIT THEN
  0 < 0=
;

\ SPACE           ::= <ASCII SP, space, 0x20>
: IsSPACE ( char -- flag )
  BL =
;

\ quoted_specials ::= <"> / "\"

: IsQuotedSpecials ( char -- flag )
  DUP [CHAR] " = SWAP [CHAR] \ = OR
;

\ QUOTED_CHAR     ::= <any TEXT_CHAR except quoted_specials> /
\                     "\" quoted_specials

: IsQUOTED_CHAR ( char -- flag )
\ после проверки этой функцией использовать дальше Look @, т.к. может измениться
  DUP [CHAR] \ = IF DROP GetNextChar Look @ IsQuotedSpecials EXIT THEN
  DUP IsTEXT_CHAR SWAP IsQuotedSpecials 0= AND
;

\ quoted          ::= <"> *QUOTED_CHAR <">
: GetQuoted ( -- s )
  { \ s }
  [CHAR] " Match
  "" -> s
  BEGIN
    Look @ IsQUOTED_CHAR
  WHILE
    Look 1 s STR+
    GetNextChar
  REPEAT
  [CHAR] " Match
  s
;

: LookString ( addr u -- flag )
\ проверить, есть ли заданная строка в текущей позиции парсинга
  TIB >IN @ 1- + OVER COMPARE-U 0=
;

: SkipString ( addr u -- flag )
\ пропустить строку addr u если она есть в текущей позиции парсинга
  DUP >IN @ 1- + SOURCE NIP > IF 2DROP FALSE EXIT THEN \ остаток строки короче
  2DUP LookString
  IF NIP 1- >IN +! GetNextChar TRUE ELSE 2DROP FALSE THEN
;

: BNF  \ инициализация Look; выполнить перед началом парсинга
  GetNextChar
;
