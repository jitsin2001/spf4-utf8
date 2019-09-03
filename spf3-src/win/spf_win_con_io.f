( Консольный ввод-вывод.
  Windows-зависимые слова.
  Copyright [C] 1992-1999 A.Cherezov ac@forth.org
  Преобразование из 16-разрядного в 32-разрядный код - 1995-96гг
  Ревизия - сентябрь 1999
  Изменения - Ruvim Pinka ноябрь 1999
)

H-STDIN  VALUE  H-STDIN    \ хэндл файла - стандартного ввода
H-STDOUT VALUE  H-STDOUT   \ хэндл файла - стандартного вывода
H-STDERR VALUE  H-STDERR   \ хэндл файла - стандартного вывода ошибок

: ACCEPT ( c-addr +n1 -- +n2 ) \ 94
\ Ввести строку максимальной длины до +n1 символов.
\ Исключительная ситуация возникает, если +n1 0 или больше 32767.
\ Отображать символы по мере ввода.
\ Ввод прерывается, когда получен символ "конец строки".
\ Ничего не добавляется в строку.
\ +n2 - длина строки, записанной по адресу c-addr.
  H-STDIN READ-LINE THROW
  0= IF -1002 THROW THEN
;

: EMIT ( x -- ) \ 94
\ Если x - изображаемый символ, вывести его на дисплей.
\ Программы, использующие управляющие символы, зависят от окружения.
  >R RP@ 1 H-STDOUT WRITE-FILE RDROP THROW
;

: CR ( -- ) \ 94
\ Перевод строки.
  LT LTL @ H-STDOUT WRITE-FILE THROW
;

: TYPE ( c-addr u -- ) \ 94
\ Если u>0 - вывести строку символов, заданную c-addr и u.
\ Программы, использующие управляющие символы, зависят от окружения.
  ANSI><OEM
  H-STDOUT WRITE-FILE THROW
;


USER NumberOfConsoleInputEvents

: EKEY? ( -- flag ) \ 93 FACILITY EXT
\ Если клавиатурное событие доступно, вернуть "истина". Иначе "ложь".
\ Событие должно быть возвращено следующим выполнением EKEY.
\ После того как EKEY? возвратило значение "истина", следующие выполнения
\ EKEY? до выполнения KEY, KEY? или EKEY также возвращают "истину",
\ относящуюся к тому же событию.
  NumberOfConsoleInputEvents H-STDIN
  GetNumberOfConsoleInputEvents DROP
  NumberOfConsoleInputEvents @
;


CREATE INPUT_RECORD ( /INPUT_RECORD) 20 ALLOT

: ControlKeysMask ( -- u )
\ вернуть маску управляющих клавиш для последнего клавиатурного события.
    [ INPUT_RECORD ( Event dwControlKeyState ) 16 + ] LITERAL  @
;

1 CONSTANT KEY_EVENT
USER NumberOfRecordsRead

: EKEY ( -- u ) \ 93 FACILITY EXT
\ Принять одно клавиатурное событие u. Кодирование клавиатурных событий
\ зависит от реализации.
\ В данной реализации 
\ byte  value
\    0  AsciiChar
\    2  ScanCod
\    3  KeyDownFlag
  NumberOfRecordsRead 2 INPUT_RECORD H-STDIN \ 1 заменен на 2 (30.12.2001 ~boa)
  ReadConsoleInputA DROP
   INPUT_RECORD ( EventType ) W@  KEY_EVENT <> IF 0 EXIT THEN
 [ INPUT_RECORD ( Event AsciiChar       ) 14 + ] LITERAL W@
 [ INPUT_RECORD ( Event wVirtualScanCode) 12 + ] LITERAL W@  16 LSHIFT OR
 [ INPUT_RECORD ( Event bKeyDown        ) 04 + ] LITERAL C@  24 LSHIFT OR
;

HEX
: EKEY>CHAR ( u -- u false | char true ) \ 93 FACILITY EXT
\ Если клавиатурное событие u соответствует символу - вернуть символ и
\ "истину". Иначе u и "ложь".
  DUP    FF000000 AND  0=   IF FALSE    EXIT THEN
  DUP    000000FF AND  ?DUP IF NIP TRUE EXIT THEN
  FALSE
;

: EKEY>SCAN ( u -- scan flag )
\ вернуть скан-код клавиши, соответствующей клавиатурному событию u
\ flag=true - клавиша нажата. flag=false - отпущена.
  DUP  10 RSHIFT  000000FF AND
  SWAP FF000000 AND 0<>
;
DECIMAL
