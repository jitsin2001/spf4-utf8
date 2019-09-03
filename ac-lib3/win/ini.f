( Работа с ini-файлами.
  Плюс упрощенный синтаксис Section[key], File.Section[key]
  Плюс исправление ошибок, когда в строчном литерале S" или "
  забывают пробел после кавычки. Примеры см. в конце текста.
  Ограничение: максимальная длина строки задается в IniMaxString, default=4000
  Задействованная память НЕ освобождается до завершения потока.
)

REQUIRE GetIniString ~af/lib/ini.f
REQUIRE STR@         ~ac/lib/str2.f

4000 VALUE IniMaxString

: IniFile@ ( S" key" S" section" S" file"  -- S" value" )
\ получить значение ключа из ini-файла
  { ka ku sa su fa fu \ mem }
  IniMaxString ALLOCATE THROW -> mem
  fa IniMaxString mem S" " DROP ka sa GetPrivateProfileStringA
  mem SWAP S@
  mem FREE THROW
;
USER IniEnumXt

: (IniEnum)
  BEGIN
    0 PARSE DUP
  WHILE
    IniEnumXt @ EXECUTE
  REPEAT 2DROP
;
: IniEnum ( a u xt -- ... )
\ выполнить xt для каждой строки в списке a u
\ a u - список asciiz-строк, возвращенных IniFile@ в случае,
\ если запрашивался список, т.е. одно из входных значений было нулевое
  IniEnumXt ! 
  ['] (IniEnum) EVALUATE-WITH
;
: IniFileExists ( addr u -- flag )
  R/O OPEN-FILE-SHARED ?DUP
  IF NIP DUP 2 =
        OVER 3 = OR
        OVER 206 = OR 
        SWAP 123 = OR
        0=
  ELSE CLOSE-FILE THROW TRUE
  THEN
;
: IniDefault2
  S" ..\Eserv3.orig.ini"
;
: IniDefault1
  S" ..\Eserv3.ini" 2DUP IniFileExists IF EXIT THEN
  2DROP IniDefault2
;
VECT IniDefault
VECT IniDefaultOrig
' IniDefault1 TO IniDefault
' IniDefault2 TO IniDefaultOrig

: STRNIL
  DUP 0= IF 2DROP 0 0 THEN
;
: File.Section[Key]>
  { \ fa fu }
  SOURCE S" ." SEARCH NIP SWAP \ flag a
  SOURCE S" [" SEARCH 2DROP \ a2
  U< AND
  IF [CHAR] . PARSE [CHAR] . PARSE 2SWAP " {s}.{s}" STR@ STRNIL
  ELSE IniDefault THEN
  -> fu -> fa
  [CHAR] [ PARSE " {s}" STR@ STRNIL
  [CHAR] ] PARSE " {s}" STR@ STRNIL 2SWAP fa fu
;
: FileOrig.Section[Key]>
  { \ fa fu }
  SOURCE S" ." SEARCH NIP SWAP \ flag a
  SOURCE S" [" SEARCH 2DROP \ a2
  U< AND
  IF [CHAR] . PARSE [CHAR] . PARSE 2SWAP " {s}.{s}" STR@ STRNIL
  ELSE IniDefaultOrig THEN
  -> fu -> fa
  [CHAR] [ PARSE " {s}" STR@ STRNIL
  [CHAR] ] PARSE " {s}" STR@ STRNIL 2SWAP fa fu
;
: (IniS@)
  File.Section[Key]>
  IniFile@ DUP 0=
  IF 2DROP >IN 0! FileOrig.Section[Key]>
     IniFile@
  THEN
;
: IniS@ ( a u -- S" value" )
  ['] (IniS@) EVALUATE-WITH
;
: ""@ { a u -- str }
  >IN @ u - 0 MAX >IN ! POSTPONE "
;
: "S"@ { a u -- str }
  >IN @ u 1- - 0 MAX >IN ! POSTPONE S"
;
: NOTFOUND { a u -- ... }
  a u S" [" SEARCH NIP NIP
  a u S" ]" SEARCH NIP NIP AND IF a u IniS@ EXIT THEN
  a C@ [CHAR] " = >IN @ u > AND IF a u ""@ EXIT THEN
  u 1 > IF a 2 S' S"' COMPARE 0= >IN @ u > AND IF a u "S"@ EXIT THEN THEN
  a u NOTFOUND
;

( win.ini отображен в реестр, поэтому данные могут не совпадать с ini )
(
g:\WINXP\win.ini.Mail[CMCDLLNAME32] TYPE CR CR
g:\WINXP\win.ini.Mail[] ' TYPE IniEnum CR CR
g:\WINXP\win.ini.[] TYPE CR CR
MyDomains[Domain1] TYPE CR
MyDomains[Domain2] TYPE CR
g:\Eserv3\acSMTP\log\schema.ini.200304mail.txt[MaxScanRows] TYPE CR
    "test{5 5 +}" STYPE CR
: TEST   S"test zzz" TYPE CR ; TEST

S" CMCDLLNAME32" S" Mail" S" g:\WINXP\win.ini" IniFile@ TYPE CR
0 0 S" Mail" S" g:\WINXP\win.ini" IniFile@ TYPE CR
0 0 0 0 S" g:\WINXP\win.ini" IniFile@ TYPE CR
)