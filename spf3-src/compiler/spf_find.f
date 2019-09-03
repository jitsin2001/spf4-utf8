( Поиск слов в словарях и управление порядком поиска.
  ОС-независимые определения.
  Copyright [C] 1992-1999 A.Cherezov ac@forth.org
  Преобразование из 16-разрядного в 32-разрядный код - 1995-96гг
  Ревизия - сентябрь 1999
)

VECT FIND

HEX \ Оптимизировано by day (29.10.2000)
CODE SEARCH-WORDLIST ( c-addr u wid -- 0 | xt 1 | xt -1 ) \ 94 SEARCH
\ Найти определение, заданное строкой c-addr u в списке слов, идентифицируемом 
\ wid. Если определение не найдено, вернуть ноль.
\ Если определение найдено, вернуть выполнимый токен xt и единицу (1), если 
\ определение немедленного исполнения, иначе минус единицу (-1).
       PUSH EDI
       MOV ESI, [EBP]                  \ вход в список
       MOV EDX, 4 [EBP]                \ длина (счетчик)
       MOV EDI, 8 [EBP]                \ искомое слово в ES:DI
 
       MOV EBX, # FFFF
       CMP EDX, # 3
       JB  SHORT @@8
       MOV  EBX, # FFFFFFFF
@@8:   
       MOV EAX, [EDI]
       SHL EAX, # 8
       OR  EDX, EAX
       AND EDX, EBX
 
       MOV ESI, [ESI]             \ адрес поля имени в DS:SI
@@1:
       OR ESI, ESI
       JZ SHORT @@2                   \ конец поиска
       MOV EAX, [ESI]
       AND EAX, EBX
       INC ESI
       CMP EAX, EDX
       JZ SHORT @@3                   \ проверить всю строку
       AND EAX, # FF
       ADD ESI, EAX               \ длины не равны - идем дальше
       MOV ESI, [ESI]
 
       JMP SHORT @@1
@@3:
       CLD
       XOR ECX, ECX
       MOV CL, DL
       PUSH EDI                  \ сохраняем адрес начала искомого слова
       REPZ CMPS BYTE
       POP EDI
       JZ SHORT @@5
       ADD ESI, ECX
       MOV ESI, [ESI]
       JMP SHORT @@1
@@2:
       ADD EBP, # 8
       MOV [EBP], DWORD # 0
       JMP SHORT @@7                  \ выход с "не найдено"
 
@@5:   AND EDX, # FF
       SUB ESI, EDX
       MOV ECX, # -1            \ "найдено"
       SUB ESI, # 6
       MOV AL, 4 [ESI]
       AND AL, # 1
       JZ SHORT @@6
       NEG ECX
@@6:   MOV EAX, [ESI]
       ADD EBP, # 4
       MOV [EBP], ECX
       MOV 4 [EBP], EAX
@@7:
       POP EDI
       RET
END-CODE
DECIMAL

USER-CREATE S-O 16 CELLS TC-USER-ALLOT \ порядок поиска
USER-VALUE CONTEXT    \ CONTEXT @ дает wid1

: FIND1 ( c-addr -- c-addr 0 | xt 1 | xt -1 ) \ 94 SEARCH
\ Расширить семантику CORE FIND следующим:
\ Искать определение с именем, заданным строкой со счетчиком c-addr.
\ Если определение не найдено после просмотра всех списков в порядке поиска,
\ возвратить c-addr и ноль. Если определение найдено, возвратить xt.
\ Если определение немедленного исполнения, вернуть также единицу (1);
\ иначе также вернуть минус единицу (-1). Для данной строки, значения,
\ возвращаемые FIND во время компиляции, могут отличаться от значений,
\ возвращаемых не в режиме компиляции.
  0
  S-O 1- CONTEXT
  DO
   OVER COUNT I @ SEARCH-WORDLIST
   ?DUP IF 2SWAP 2DROP LEAVE THEN
   I S-O = IF LEAVE THEN
   1 CELLS NEGATE
  +LOOP
;

: SFIND ( addr u -- addr u 0 | xt 1 | xt -1 ) \ 94 SEARCH
\ Расширить семантику CORE FIND следующим:
\ Искать определение с именем, заданным строкой addr u.
\ Если определение не найдено после просмотра всех списков в порядке поиска,
\ возвратить addr u и ноль. Если определение найдено, возвратить xt.
\ Если определение немедленного исполнения, вернуть также единицу (1);
\ иначе также вернуть минус единицу (-1). Для данной строки, значения,
\ возвращаемые FIND во время компиляции, могут отличаться от значений,
\ возвращаемых не в режиме компиляции.
  S-O 1- CONTEXT
  DO
   2DUP I @ SEARCH-WORDLIST
   ?DUP IF 2SWAP 2DROP UNLOOP EXIT THEN
   I S-O = IF LEAVE THEN
   1 CELLS NEGATE
  +LOOP
  0
;

: DEFINITIONS ( -- ) \ 94 SEARCH
\ Сделать списком компиляции тот же список слов, что и первый список в порядке 
\ поиска. Имена последующих определений будут помещаться в список компиляции.
\ Последующие изменения порядка поиска не влияют на список компиляции.
  CONTEXT @ SET-CURRENT
;

: GET-ORDER ( -- widn ... wid1 n ) \ 94 SEARCH
\ Возвращает количество списков слов в порядке поиска - n и идентификаторы 
\ widn ... wid1, идентифицирующие эти списки слов. wid1 - идентифицирует список 
\ слов, который просматривается первым, и widn - список слов, просматриваемый 
\ последним. Порядок поиска не изменяется.
  CONTEXT 1+ S-O DO I @ 1 CELLS +LOOP
  CONTEXT S-O - 1 CELLS / 1+
;

: FORTH ( -- ) \ 94 SEARCH EXT
\ Преобразовать порядок поиска, состоящий из widn, ...wid2, wid1 (где wid1 
\ просматривается первым) в widn,... wid2, widFORTH-WORDLIST.
  FORTH-WORDLIST CONTEXT !
;

: ONLY ( -- ) \ 94 SEARCH EXT
\ Установить список поиска на зависящий от реализации минимальный список поиска.
\ Минимальный список поиска должен включать слова FORTH-WORDLIST и SET-ORDER.
  S-O TO CONTEXT
  FORTH
;

: SET-ORDER ( widn ... wid1 n -- ) \ 94 SEARCH
\ Установить порядок поиска на списки, идентифицируемые widn ... wid1.
\ Далее список слов wid1 будет просматриваться первым, и список слов widn
\ - последним. Если n ноль - очистить порядок поиска. Если минус единица,
\ установить порядок поиска на зависящий от реализации минимальный список
\ поиска.
\ Минимальный список поиска должен включать слова FORTH-WORDLIST и SET-ORDER.
\ Система должна допускать значения n как минимум 8.
  ?DUP IF DUP -1 = IF DROP ONLY EXIT THEN
          DUP 1- CELLS S-O + TO CONTEXT
          0 DO CONTEXT I CELLS - ! LOOP
       ELSE S-O TO CONTEXT  CONTEXT 0! THEN
;


: ALSO ( -- ) \ 94 SEARCH EXT
\ Преобразовать порядок поиска, состоящий из widn, ...wid2, wid1 (где wid1 
\ просматривается первым) в widn,... wid2, wid1, wid1. Неопределенная ситуация 
\ возникает, если в порядке поиска слишком много списков.
  GET-ORDER 1+ OVER SWAP SET-ORDER
;
: PREVIOUS ( -- ) \ 94 SEARCH EXT
\ Преобразовать порядок поиска, состоящий из widn, ...wid2, wid1 (где wid1 
\ просматривается первым) в widn,... wid2. Неопределенная ситуация возникает,
\ если порядок поиска был пуст перед выполнением PREVIOUS.
  CONTEXT 1 CELLS - S-O MAX TO CONTEXT
;

: VOC-NAME. ( wid -- ) \ напечатать имя списка слов, если он именован
  DUP FORTH-WORDLIST = IF DROP ." FORTH" EXIT THEN
  DUP CELL+ @ ?DUP IF ID. DROP ELSE ." <NONAME>:" U. THEN
;

: ORDER ( -- ) \ 94 SEARCH EXT
\ Показать списки в порядке поиска, от первого просматриваемого списка до 
\ последнего. Также показать список слов, куда помещаются новые определения.
\ Формат изображения зависит от реализации.
\ ORDER может быть реализован с использованием слов форматного преобразования
\ чисел. Следовательно он может разрушить перемещаемую область, 
\ идентифицируемую #>.
  GET-ORDER ." Context: "
  0 ?DO ( DUP .) VOC-NAME. SPACE LOOP CR
  ." Current: " GET-CURRENT VOC-NAME. CR
;

: LATEST ( -> NFA )
  CURRENT @ @
;
