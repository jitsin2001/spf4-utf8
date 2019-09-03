( Интерфейсы с Windows - определения в словаре импортируемых 
  функций Windows и экспортируемых функций [callback, wndproc и т.п.]
  Windows-зависимые определения.
  Copyright [C] 1992-1999 A.Cherezov ac@forth.org
  Преобразование из 16-разрядного в 32-разрядный код - 1995-96гг
  Ревизия - сентябрь 1999
)

VARIABLE WINAP
VARIABLE WINAPLINK

: WINAPI: ( "ИмяПроцедуры" "ИмяБиблиотеки" -- )
  ( Используется для импорта WIN32-процедур.
    Полученное определение будет иметь имя "ИмяПроцедуры".
    Поле address of winproc будет заполнено в момент первого
    выполнения полученной словарной статьи.
    Для вызова полученной "импортной" процедуры параметры
    помещаются на стек данных в порядке, обратном описанному
    в Си-вызове этой процедуры. Результат выполнения функции
    будет положен на стек.
  )
  >IN @
  HEADER
  >IN !
  ['] _WINAPI-CODE COMPILE,
  HERE WINAP !
  0 , \ address of winproc
  0 , \ address of library name
  0 , \ address of function name
\  0 , \ # of parameters
  HERE WINAPLINK @ , WINAPLINK ! ( связь )
  HERE WINAP @ CELL+ CELL+ !
  HERE >R
  NextWord HERE SWAP DUP ALLOT MOVE 0 C, \ имя функции
  HERE WINAP @ CELL+ !
  HERE >R
  NextWord HERE SWAP DUP ALLOT MOVE 0 C, \ имя библиотеки
  R> LoadLibraryA DUP 0= IF -2009 THROW THEN \ ABORT" Library not found"
  R> SWAP GetProcAddress 0= IF -2010 THROW THEN \ ABORT" Procedure not found"
;

: EXTERN ( xt1 -- xt2 )
  HERE
  ['] FORTH-INSTANCE> COMPILE,
  SWAP COMPILE,
  ['] <FORTH-INSTANCE COMPILE,
  RET,
;
: WNDPROC: ( xt "name" -- )
  EXTERN
  HEADER
  ['] _WNDPROC-CODE COMPILE,
  ,
;
: TASK ( xt1 -- xt2 )
  EXTERN
  HERE SWAP
  ['] _WNDPROC-CODE COMPILE,
  ,
;
: TASK: ( xt "name" -- )
  TASK CONSTANT
;
VARIABLE ERASED-CNT

: ERASE-IMPORTS
  \ обнуление адресов импортируемых процедур
  WINAPLINK
  BEGIN
    @ DUP
  WHILE
    DUP 3 CELLS - 0!
  REPEAT DROP
;
