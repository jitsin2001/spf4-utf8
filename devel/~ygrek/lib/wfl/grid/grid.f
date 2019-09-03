\ $Id$

\ Идея ~yz
\ Контролы размещаются в сетках, которые можно растягивать
\ alpha

REQUIRE WFL ~day/wfl/wfl.f
NEEDS ~ygrek/lib/list/all.f
NEEDS lib/include/core-ext.f
NEEDS ~profit/lib/logic.f
NEEDS lib/ext/debug/accert.f
NEEDS ~pinka/samples/2006/syntax/qname.f
REQUIRE +METHODS ~ygrek/lib/hype/ext.f

0 VALUE indent

: inc-indent indent 2 + TO indent ;
: dec-indent indent 2 - TO indent ;

\ -----------------------------------------------------------------------

: (DO-PRINT-VARIABLE) ( a u addr -- ) -ROT TYPE ."  = " @ . ;

: PRINT: ( "name" -- )
   PARSE-NAME
   2DUP
   POSTPONE SLITERAL
   EVALUATE
   POSTPONE (DO-PRINT-VARIABLE) ; IMMEDIATE

\ -----------------------------------------------------------------------

CLASS CGridBoxData
 VAR _yspan \ флаг - растяжение ячейки по высоте
 VAR _xspan \ флаг - растяжение ячейки по ширине
 VAR _ymin  \ минимальная высота контрола внутри ячейки
 VAR _xmin  \ минимальная ширина контрола внутри ячейки
 VAR _xpad  \ обрамление по ширине
 VAR _ypad  \ обрамление по высоте
 VAR _xfill \ флаг - растяжение контрола за ячейкой по ширине
 VAR _yfill \ флаг - растяжение контрола за ячейкой по высоте

: :print
   PRINT: _xmin
   PRINT: _xspan

   PRINT: _ymin
   PRINT: _yspan 
;

;CLASS

CGridBoxData NEW DefaultBox

30 DefaultBox _ymin !
50 DefaultBox _xmin !
TRUE DefaultBox _xspan !
TRUE DefaultBox _yspan !
TRUE DefaultBox _xfill !
TRUE DefaultBox _yfill !
10 DefaultBox _xpad !
5 DefaultBox _ypad !

\ -----------------------------------------------------------------------

\ Базовый элемент сетки - ячейка
CGridBoxData SUBCLASS CGridBox

 VAR _h     \ актуальная высота
 VAR _w     \ актуальная ширина
 VAR _obj   \ обьект-контрол

init:
  0 _h !
  0 _w !
  0 _obj !
  \ ugh, ugly!
  DefaultBox _xmin @ SUPER _xmin !
  DefaultBox _ymin @ SUPER _ymin !
  DefaultBox _xspan @ SUPER _xspan !
  DefaultBox _yspan @ SUPER _yspan !
  DefaultBox _xfill @ SUPER _xfill !
  DefaultBox _yfill @ SUPER _yfill !
  DefaultBox _xpad @ SUPER _xpad !
  DefaultBox _ypad @ SUPER _ypad !
;

: :yspan? SUPER _yspan @ ;
: :xspan? SUPER _xspan @ ;

: :xmin SUPER _xmin @ SUPER _xpad @ 2 * + ;
: :ymin SUPER _ymin @ SUPER _ypad @ 2 * + ;

: :xfill? SUPER _xfill @ ;
: :yfill? SUPER _yfill @ ;

\ : :xpad SUPER _xpad @ ;
\ : :ypad SUPER _ypad @ ;

\ выполнить растяжку по x если ячейка растягиваема
: :xformat ( given -- ) :xspan? NOT IF DROP 0 THEN :xmin MAX _w ! ;
\ выполнить растяжку по y если ячейка растягиваема
: :yformat ( given -- ) :yspan? NOT IF DROP 0 THEN :ymin MAX _h ! ;

: :h _h @ ;
: :w _w @ ;

: :print
   SUPER :print
   PRINT: _w
   PRINT: _h
;

: :control! ( ctl-obj -- ) _obj ! ;

: :finalize { x y res -- } 
    _obj @ 0= IF EXIT THEN 
    \ h
    :yfill? IF :h SUPER _ypad @ 2 * - ELSE SUPER _ymin @ THEN 0 MAX
    \ w 
    :xfill? IF :w SUPER _xpad @ 2 * - ELSE SUPER _xmin @ THEN 0 MAX
    \ y 
    y :yfill? IF SUPER _ypad @ ELSE :h SUPER _ymin @ - 2 / THEN +
    \ x
    x :xfill? IF SUPER _xpad @ ELSE :w SUPER _xmin @ - 2 / THEN +
    _obj @ res => :resize ;

;CLASS

: FORLIST ( l -- )
   S" >R BEGIN R@ list::empty? NOT WHILE R@ list::car" EVALUATE
; IMMEDIATE

: ENDFOR 
   S" R> list::cdr >R REPEAT RDROP" EVALUATE
; IMMEDIATE

\ --------------------------

\ ряд ячеек как одна ячейка
CLASS CGridRow

 VAR _cells \ список ячеек этого ряда
 VAR _w 
 VAR _h

init: list::nil _cells ! ;

: :add ( cell -- ) _cells @ list::append _cells ! ;

: traverse-row ( xt -- ) _cells @ SWAP list::iter ;

\ минимальная ширина ряда как сумма минимальной ширины каждой ячейки
: :xmin ( -- n ) 0 LAMBDA{ => :xmin + } traverse-row ;
\ минимальная высота ряда как сумма минимальной высоты каждой ячейки
: :ymin ( -- n ) 0 LAMBDA{ => :ymin MAX } traverse-row ;

: :xspan? ( -- ? ) _cells @ LAMBDA{ => :xspan? } list::find NIP ;
: :yspan? ( -- ? ) _cells @ LAMBDA{ => :yspan? } list::find NIP ;

\ число ячеек которые можно растянуть по горизонтали
: :xspan-count ( -- n ) 0 LAMBDA{ => :xspan? IF 1 + THEN } traverse-row ;

: :xformat { given | extra -- }
   :xspan-count \ если у нас есть внутри потребители - отдаём всё им
   DUP
   IF
    given :xmin - 0 MAX SWAP / 
   ELSE 
    DROP 0
   THEN 
    -> extra

    \ раздадим xmin + extra каждой клетке
    \ те у которых xspan включен займут его
    _cells @
    FORLIST
     >R R@ => :xmin extra + R> => :xformat
    ENDFOR

\    extra 0 = IF given SUPER :xformat THEN \ wth? FIXME

   0 LAMBDA{ => :w + } traverse-row
   \ given MAX
   _w !
;

: :yformat ( given -- )
   \ дать каждой ячейке растянуться не более чем на given
   LAMBDA{ OVER SWAP => :yformat } traverse-row
   DROP

   \ сколько места осталось нераспределённым?
   0 LAMBDA{ => :h MAX } traverse-row 
   \ given MAX 
   _h !
;

: :w _w @ ;
: :h _h @ ;

: :print ( -- )
\   CR ." CGridRow :print"
   CR
   indent SPACES
   ." Row: " \ SUPER :print
   inc-indent   
   CR indent SPACES ." Cells : "
   LAMBDA{ CR indent SPACES => :print } traverse-row
   dec-indent
;

: :draw { | x }
   0 -> x
   _cells @
   BEGIN
    DUP list::empty? 0=
   WHILE
    x 3 .R SPACE
    DUP list::car => _w @ x + -> x
    list::cdr
   REPEAT
   DROP
   x 3 .R SPACE
\   SUPER _w @ 3 .R SPACE
;

: :finalize { x y res | obj -- }
   _cells @
   FORLIST
    -> obj
    x y res obj => :finalize
    obj => :w x + -> x
   ENDFOR ;

;CLASS

\ --------------------------

\ Сетка - это список рядов
\ и одновременно также одна ячейка
CLASS CGrid

 VAR _rows
 VAR _w
 VAR _h

init: list::nil _rows ! ;

: traverse-grid ( xt -- ) _rows @ SWAP list::iter ;

: :xmin ( -- n ) 0 LAMBDA{ => :xmin MAX } traverse-grid ;
: :ymin ( -- n ) 0 LAMBDA{ => :ymin + } traverse-grid ;

: :xspan? ( -- ? ) _rows @ LAMBDA{ => :xspan? } list::find NIP ;
: :yspan? ( -- ? ) _rows @ LAMBDA{ => :yspan? } list::find NIP ;

\ число рядов которые можно растянуть по вертикали
: :yspan-count ( -- n ) 0 LAMBDA{ => :yspan? 1 AND + } traverse-grid ;

: :yformat { given | extra -- }
   :yspan-count \ если у нас есть внутри потребители - отдаём всё им
   DUP
   IF
    given :ymin - 0 MAX SWAP / 
   ELSE 
    DROP 0
   THEN 
    -> extra

    \ раздадим xmin + extra каждой клетке
    \ те у которых xspan включен займут его
    _rows @
    FORLIST
     >R R@ => :ymin extra + R> => :yformat
    ENDFOR
    0 LAMBDA{ => :h + } traverse-grid _h !
;

: :xformat ( given -- )
   LAMBDA{ OVER SWAP => :xformat } traverse-grid
   DROP 
   0 LAMBDA{ => :w MAX } traverse-grid _w !
   ;

: :w _w @ ;
: :h _h @ ;

: :add ( row -- ) 0 OVER => :xformat 0 OVER => :yformat _rows @ list::append _rows ! ;

: :print ( -- )
\   CR ." CGrid :print"
   CR indent SPACES ." Grid: " 
\   CR ." Rows----- "
  inc-indent
   LAMBDA{ CR indent SPACES => :print } traverse-grid
   dec-indent
\   CR ." ------End"
;

: :draw { | y }
   0 -> y
   _rows @
   BEGIN
    DUP list::empty? 0=
   WHILE
    CR y 3 .R SPACE ." --->"
    DUP list::car => :draw
    DUP list::car => :h y + -> y
    list::cdr
   REPEAT
   DROP
;

: :finalize { x y res | obj -- }
   _rows @ 
   FORLIST 
    -> obj
    x y res obj => :finalize
    obj => :h y + -> y
   ENDFOR
;

;CLASS

\ -----------------------------------------------------------------------

\ макросы
\ +имя - включает булевый параметр (например +xspan включает растяжку по ширине)
\ -имя - выключает
\ =имя - устанавливает параметр в указанное значение (например S" text" =text или 20 =xpad )
\ Все установки действуют на последний размещённый элемент

\ Установка параметров после слова DEFAULTS меняет свойства по-умолчанию для текущей сетки (внутри GRID ;GRID)
\ Если же установить параметры для DEFAULTS вне сетки то это (логично) изменяет глобальные умолчания.
\ Установки по-умолчанию изначальные :) такие 
\ +xspan +yspan 10 =xpad 5 =ypad 50 =xmin 30 =ymin

\ FIXME возможно у CGrid должны быть свойства pad? А может и у Row?
\ Но у них нет и по-моему не должно быть свойства span..

\ память, ресурсы - всё течет

\ MODULE: WG

0 VALUE box \ текущая ячейке
0 VALUE ctl  \ контрол в текущей ячейке
0 VALUE row  \ текущий ряд
0 VALUE grid \ текущая сетка
0 VALUE parent

\ создать новую клетку в текущем ряду и поместить в неё контрол класса class
: put-box ( box -- )
   TO box
   box row => :add ;

: (put) ( obj -- )
   TO ctl
   CGridBox NewObj put-box
   parent SELF ctl => create DROP
   ctl box => :control! ;

: put ( class -- ) NewObj (put) ;

\ начать новый ряд клеток
: ROW ( -- )
  CGridRow NewObj TO row
  row grid => :add
;

list::nil VALUE grid-vars

: save-vars ( -- ) 
   %[ parent % grid % row % box % 
      DefaultBox _ymin @ % 
      DefaultBox _xmin @ % 
      DefaultBox _xspan @ % 
      DefaultBox _yspan @ % 
      DefaultBox _xpad @ %
      DefaultBox _ypad @ %
      DefaultBox _xfill @ %
      DefaultBox _yfill @ %
   ]% grid-vars list::cons TO grid-vars ;

: restore-vars 
   grid-vars list::car >R
   grid-vars list::cdr TO grid-vars
   R@ list::all DROP ( ... )
   DefaultBox _yfill !
   DefaultBox _xfill !
   DefaultBox _ypad !
   DefaultBox _xpad !
   DefaultBox _yspan !
   DefaultBox _xspan !
   DefaultBox _xmin !
   DefaultBox _ymin !
   TO box
   TO row
   TO grid
   TO parent
   R> list::free ;

: DEFAULTS DefaultBox this TO box ;

\ начать новую таблицу
\ сохранить значения параметров сетки по-умолчания
: GRID ( parent -- )
   save-vars
   TO parent
   CGrid NewObj TO grid
   ROW ;

\ закончить таблицу
\ восстановить сохранённые значения параметров сетки по-умолчанию
: ;GRID ( -- grid ) grid >R restore-vars R> ;

: xspan! ( ? -- ) box :: CGridBox._xspan ! ;

\ включить растяжение клетки по ширине
: +xspan ( -- ) TRUE xspan! ;
\ выключить растяжение клетки по ширине
: -xspan ( -- ) FALSE xspan! ;

: yspan! ( ? -- ) box :: CGridBox._yspan ! ;

\ выключить растяжение клетки по высоте
: +yspan ( -- ) TRUE yspan! ;
\ выключить растяжение клетки по высоте
: -yspan ( -- ) FALSE yspan! ;

: -span -xspan -yspan ;
: +span +xspan +yspan ;

\ установить обработчик события
\ xt: ( obj -- )
: =command ( xt -- ) ctl => setHandler ;
: =text ( a u -- ) ctl => setText ;

: =xmin ( u -- ) box :: CGridBox._xmin ! ;
: =ymin ( u -- ) box :: CGridBox._ymin ! ;

: =xpad ( u -- ) box :: CGridBox._xpad ! ;
: =ypad ( u -- ) box :: CGridBox._ypad ! ;

: =pad DUP =xpad =ypad ;
: -pad 0 =pad ;

: xfill! ( ? -- ) box :: CGridBox._xfill ! ;
: +xfill ( -- ) TRUE xfill! ;
: -xfill ( -- ) FALSE xfill! ;

: yfill! ( ? -- ) box :: CGridBox._yfill ! ;
: +yfill ( -- ) TRUE yfill! ;
: -yfill ( -- ) FALSE yfill! ;

: -fill -xfill -yfill ;
: +fill +xfill +yfill ;

\ ;MODULE

\ -----------------------------------------------------------------------

CRect +METHODS

: rawCopyFrom ( ^RECT -- ) addr 4 CELLS CMOVE ;
: rawCopyTo ( ^RECT -- ) addr SWAP 4 CELLS CMOVE ;

\ NB @ and ! are redefined in CRect
: height! ( u -- ) top FORTH::@ + bottom FORTH::! ;
: width! ( u -- ) left FORTH::@ + right FORTH::! ;

;CLASS

\ -----------------------------------------------------------------------

CLASS CResizer
: fail TRUE S" override!" SUPER abort ;
: :start ( -- ) fail ;
: :resize ( h w y x obj -- ) fail ;
: :finish ( -- ) fail ;
;CLASS

CResizer SUBCLASS CSimpleResizer
: :start ;
: :resize { h w y x obj } TRUE h w y x obj => moveWindow ;
: :finish ;
;CLASS

WINAPI: BeginDeferWindowPos USER32.DLL
WINAPI: DeferWindowPos USER32.DLL
WINAPI: EndDeferWindowPos USER32.DLL

\ actually it doesn't prevent flickering..
\ removing CS_*REDRAW from class styles helps a little bit though

CResizer SUBCLASS CDeferingResizer
 VAR _hdwp

: abort SUPER abort ;

: :start 
   _hdwp @ 0 <> `already abort
   20 BeginDeferWindowPos _hdwp !
   _hdwp @ 0 = `failed abort ;

: :finish
   _hdwp @ 0 = `notready abort
   _hdwp @ EndDeferWindowPos 0 = `failed abort
   \ no cleanup needed (?)
   0 _hdwp ! ;

: :resize { h w y x obj -- }
   SWP_NOZORDER
   h w y x 0 obj => checkWindow _hdwp @ 
   DeferWindowPos _hdwp !
   _hdwp @ 0 = `failed abort ;

;CLASS

\ Контроллер для управления сеткой
\ Использование :
\ - обьявить обьект класса CGridController
\ - назначить ему сетку с помощью :grid!
\ - присоединить контроллер к окну (диалогу, контролу)
\
\ Контроллер будет перехватывать сообщения WM_SIZE и WM_SIZING 
\ и изменять содержимое сетки соответствующим образом
CMsgController SUBCLASS CGridController

  VAR _g
  CDeferingResizer OBJ _resizer
  \ CSimpleResizer OBJ _resizer

: :resize ( w h -- )
   ACCERT3( CR ." :resize " 2DUP . . )
   _g @ => :yformat
   _g @ => :xformat
   _resizer :start
   0 0 _resizer this _g @ => :finalize 
   _resizer :finish
   \ TRUE 0 SUPER parent-obj@ => checkWindow InvalidateRect DROP
    ;

: :grid _g @ ;

: :minsize ( w h -- w1 h1 )
   ACCERT3( 2DUP SWAP CR ." PREMIN : w = " . ." h = " . )
   _g @ => :ymin 30 + \ FIXME высота заголовка
   MAX
   SWAP
   _g @ => :xmin 8 + \ FIXME ширина рамки
   MAX
   ACCERT3( 2DUP CR ." MIN : w = " . ." h = " . )
   SWAP ;

: :grid! _g ! ;
: :hw _g @ => :h _g @ => :w ;

W: WM_SIZE 
   SUPER msg lParam @ LOWORD SUPER msg lParam @ HIWORD :resize
   FALSE
;

W: WM_SIZING ( -- n )
   \ CR ." WM_SIZING"
   SUPER msg lParam @
   || R: lpar CRect r ||
   lpar @ r rawCopyFrom
\    CR r width . r height .
   r width r height :minsize r height! r width!
\   CR r width . r height .
   lpar @ r rawCopyTo
   TRUE
;

: :init { win }
  _g @ 0= S" Setup controls grid with :grid! before attaching controller" SUPER abort
  win => getClientRect DROP DROP SWAP :minsize :resize
  FALSE :hw win => getClientRect 2SWAP 2DROP SWAP win => clientToScreen SWAP win => moveWindow 
  ;

\ RFD: is it ok to automatically resize grid when controller is injected?
: onAttached SUPER parent-obj@ :init ;

;CLASS

\ -----------------------------------------------------------------------
