\ 21-06-2005 ~mOleg
\ Copyright [C] 2006-2007 mOleg mininoleg@yahoo.com
\ оставить по одному экземпляру id словарей на стеке

 REQUIRE ?DEFINED devel\~moleg\lib\util\ifdef.f

        0 VALUE acc

\ не использовать! обращается к стеку возвратов!
: (scan) ( wid n --> )
          2DUP
          BEGIN DUP WHILE
            2DUP CELLS RP+@ <> WHILE 1-
           REPEAT -1 EXIT
          THEN 0 ;

\ очистить список взятый по GET-ORDER от дублирования словарей
: prepare ( wida widb ... widn n --> wida widb ... widn n )
        1- TO acc

        >R 1 >R

        \ ищем в списке
        BEGIN acc WHILE
           R> (scan)
             IF    2DROP >R DROP
              ELSE 2DROP 1+ 2>R
             THEN
          acc 1- TO acc
        REPEAT

        \ выкладываем на стек данных
        R> DUP TO acc
        BEGIN DUP WHILE R> SWAP 1- REPEAT
        DROP acc ;

?DEFINED test{ \EOF -- тестовая секция ---------------------------------------

test{ \ просто проверяем собирабельность кода
  S" passed" TYPE
}test

\EOF Использовать в FIND
     Ускорить поиск слов в словаре, особенно для случая, когда
     вызываемое слово находится в самом низу контекста можно, убрав
     все повторения словарей из списка контекста.

        То есть, если в контексте будет:

        ROOT FORTH FORTH

        то после prepare останется:

        ROOT FORTH

        Соответственно, порядок поиска не нарушается, повторные
упоминания словарей вне зависимости от их порядка и колличества повторов
исключаются.

