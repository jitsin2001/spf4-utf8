\ $Id$

( Файловый ввод-вывод.
  Windows-зависимые слова.
  Copyright [C] 1992-1999 A.Cherezov ac@forth.org
  Преобразование из 16-разрядного в 32-разрядный код - 1995-96гг
  Ревизия - сентябрь 1999
)

: CLOSE-FILE ( fileid -- ior ) \ 94 FILE
\ Закрыть файл, заданный fileid.
\ ior - определенный реализацией код результата ввода/вывода.
  CloseHandle ERR
;

: CREATE-FILE ( c-addr u fam -- fileid ior ) \ 94 FILE
\ Создать файл с именем, заданным c-addr u, и открыть его в соответствии
\ с методом доступа fam. Смысл значения fam определен реализацией.
\ Если файл с таким именем уже существует, создать его заново как
\ пустой файл.
\ Если файл был успешно создан и открыт, ior нуль, fileid его идентификатор,
\ и указатель чтения/записи установлен на начало файла.
\ Иначе ior - определенный реализацией код результата ввода/вывода,
\ и fileid неопределен.
  NIP SWAP >R >R
  0 FILE_ATTRIBUTE_ARCHIVE ( template attrs )
  CREATE_ALWAYS
  0 ( secur )
  0 ( share )  
  R> ( access=fam )
  R> ( filename )
  CreateFileA DUP -1 = IF GetLastError ELSE 0 THEN
;

CREATE SA 12 , 0 , 1 ,

: CREATE-FILE-SHARED ( c-addr u fam -- fileid ior )
  NIP SWAP >R >R
  0 FILE_ATTRIBUTE_ARCHIVE ( template attrs )
  CREATE_ALWAYS
  SA ( secur )
  3 ( share )  
  R> ( access=fam )
  R> ( filename )
  CreateFileA DUP -1 = IF GetLastError ELSE 0 THEN
;
: OPEN-FILE-SHARED ( c-addr u fam -- fileid ior )
  NIP SWAP 2>R
  0 FILE_ATTRIBUTE_ARCHIVE ( template attrs )
  OPEN_EXISTING
  SA ( secur )
  7 ( FILE_SHARE_READ FILE_SHARE_WRITE OR FILE_SHARE_DELETE OR )
  2R@ ( access=fam , filename )
  CreateFileA DUP -1 = 
  IF GetLastError DUP 87 =
     IF
       2DROP
       0 FILE_ATTRIBUTE_ARCHIVE ( template attrs )
       OPEN_EXISTING
       SA ( secur )
       3 ( FILE_SHARE_READ FILE_SHARE_WRITE OR ) \ Win9x, Bug #3104038
       2R@ ( access=fam , filename )
       CreateFileA DUP -1 =
       IF GetLastError ELSE 0 THEN
     THEN
  ELSE 0 THEN
  RDROP RDROP
;
: DELETE-FILE ( c-addr u -- ior ) \ 94 FILE
\ Удалить файл с именем, заданным строкой c-addr u.
\ ior - определенный реализацией код результата ввода/вывода.
  DROP DeleteFileA ERR
;

USER lpDistanceToMoveHigh

: FILE-POSITION ( fileid -- ud ior ) \ 94 FILE
\ ud - текущая позиция в файле, идентифицируемом fileid.
\ ior - определенный реализацией код результата ввода/вывода.
\ ud неопределен, если ior не ноль.
  >R FILE_CURRENT lpDistanceToMoveHigh DUP 0! 0 R>
  SetFilePointer
  DUP -1 = IF GetLastError ELSE 0 THEN
  lpDistanceToMoveHigh @ SWAP
;

: FILE-SIZE ( fileid -- ud ior ) \ 94 FILE
\ ud - размер в символах файла, идентифицируемом fileid.
\ ior - определенный реализацией код результата ввода/вывода.
\ Эта операция не влияет на значение, возвращаемое FILE-POSITION.
\ ud неопределен, если ior не ноль.
  lpDistanceToMoveHigh SWAP
  GetFileSize
  DUP -1 = IF GetLastError ELSE 0 THEN
  lpDistanceToMoveHigh @ SWAP
;

: OPEN-FILE ( c-addr u fam -- fileid ior ) \ 94 FILE
\ Открыть файл с именем, заданным строкой c-addr u, с методом доступа fam.
\ Смысл значения fam определен реализацией.
\ Если файл успешно открыт, ior ноль, fileid его идентификатор, и файл
\ позиционирован на начало.
\ Иначе ior - определенный реализацией код результата ввода/вывода,
\ и fileid неопределен.
  NIP SWAP >R >R
  0 FILE_ATTRIBUTE_ARCHIVE ( template attrs )
  OPEN_EXISTING
  0 ( secur )
  0 ( share )  
  R> ( access=fam )
  R> ( filename )
  CreateFileA DUP -1 = IF GetLastError ELSE 0 THEN
;

USER lpNumberOfBytesRead

: READ-FILE ( c-addr u1 fileid -- u2 ior ) \ 94 FILE
\ Прочесть u1 символов в c-addr из текущей позиции файла,
\ идентифицируемого fileid.
\ Если u1 символов прочитано без исключений, ior ноль и u2 равен u1.
\ Если конец файла достигнут до прочтения u1 символов, ior ноль
\ и u2 - количество реально прочитанных символов.
\ Если операция производится когда значение, возвращаемое
\ FILE-POSITION равно значению, возвращаемому FILE-SIZE для файла
\ идентифицируемого fileid, ior и u2 нули.
\ Если возникла исключительная ситуация, то ior - определенный реализацией
\ код результата ввода/вывода, и u2 - количество нормально переданных в
\ c-addr символов.
\ Неопределенная ситуация возникает, если операция выполняется, когда
\ значение, возвращаемое FILE-POSITION больше чем значение, возвращаемое
\ FILE-SIZE для файла, идентифицируемого fileid, или требуемая операция
\ пытается прочесть незаписанную часть файла.
\ После завершения операции FILE-POSITION возвратит следующую позицию
\ в файле после последнего прочитанного символа.
  >R 2>R
  0 lpNumberOfBytesRead R> R> R>
  ReadFile ERR
  lpNumberOfBytesRead @ SWAP
  DUP 109 = IF DROP 0 THEN \ broken pipe - обычно не ошибка, а конец входного потока данных
;

: REPOSITION-FILE ( ud fileid -- ior ) \ 94 FILE
\ Перепозиционировать файл, идентифицируемый fileid, на ud.
\ ior - определенный реализацией код результата ввода-вывода.
\ Неопределенная ситуация возникает, если позиционируется вне
\ его границ.
\ После завершения операции FILE-POSITION возвращает значение ud.
  >R lpDistanceToMoveHigh ! FILE_BEGIN lpDistanceToMoveHigh ROT R>
  SetFilePointer
  -1 = IF GetLastError ELSE 0 THEN
;


USER _fp1
USER _fp2
USER _addr

: READ-LINE ( c-addr u1 fileid -- u2 flag ior ) \ 94 FILE
\ Прочесть следующую строку из файла, заданного fileid, в память
\ по адресу c-addr. Читается не больше u1 символов. До двух
\ определенных реализацией символов "конец строки" могут быть
\ прочитаны в память за концом строки, но не включены в счетчик u2.
\ Буфер строки c-addr должен иметь размер как минимум u1+2 символа.
\ Если операция успешна, flag "истина" и ior ноль. Если конец строки
\ получен до того как прочитаны u1 символов, то u2 - число реально
\ прочитанных символов (0<=u2<=u1), не считая символов "конец строки".
\ Когда u1=u2 конец строки уже получен.
\ Если операция производится, когда значение, возвращаемое
\ FILE-POSITION равно значению, возвращаемому FILE-SIZE для файла,
\ идентифицируемого fileid, flag "ложь", ior ноль, и u2 ноль.
\ Если ior не ноль, то произошла исключительная ситуация и ior -
\ определенный реализацией код результата ввода-вывода.
\ Неопределенная ситуация возникает, если операция выполняется, когда
\ значение, возвращаемое FILE-POSITION больше чем значение, возвращаемое
\ FILE-SIZE для файла, идентифицируемого fileid, или требуемая операция
\ пытается прочесть незаписанную часть файла.
\ После завершения операции FILE-POSITION возвратит следующую позицию
\ в файле после последнего прочитанного символа.
  DUP >R
  FILE-POSITION IF 2DROP 0 0 THEN _fp1 ! _fp2 !
  LTL @ +
  OVER _addr !

  R@ READ-FILE ?DUP IF NIP RDROP 0 0 ROT EXIT THEN

  DUP >R 0= IF RDROP RDROP 0 0 0 EXIT THEN \ были в конце файла

  _addr @ R@ EOLN SEARCH
  IF   \ найден разделитель строк
     DROP _addr @ -
     DUP
     LTL @ + S>D _fp2 @ _fp1 @ D+ RDROP R> REPOSITION-FILE DROP
  ELSE \ не найден разделитель строк
     2DROP
     R> RDROP  \ если строка прочитана не полностью - будет разрезана
  THEN
  TRUE 0
;


USER lpNumberOfBytesWritten  \ not used by core more

: WRITE-FILE ( c-addr u fileid -- ior ) \ 94 FILE
\ Записать u символов из c-addr в файл, идентифицируемый fileid,
\ в текущую позицию.
\ ior - определенный реализацией код результата ввода-вывода.
\ После завершения операции FILE-POSITION возвращает следующую
\ позицию в файле за последним записанным в файл символом, и
\ FILE-SIZE возвращает значение большее или равное значению,
\ возвращаемому FILE-POSITION.
  OVER >R
  >R 2>R
  0 SP@ 0 SWAP R> R> R>
  WriteFile ERR ( u2 ior )
  ?DUP IF RDROP NIP EXIT THEN
  R> <>
  ( если записалось не столько, сколько требовалось, то тоже ошибка )
;
\ Использована адресуемая ячейка на стеке данных вместо USER-переменной,
\ чтобы вывод работал даже при неверном значении TlsIndex.
\ Решение несколько ограничено в портабельности, но сама платформа
\ Windows ограничивает сильней, чем такие трюки ;-)
\ ~ruv, 11.2008


: RESIZE-FILE ( ud fileid -- ior ) \ 94 FILE
\ Установить размер файла, идентифицируемого fileid, равным ud.
\ ior - определенный реализацией код результата ввода-вывода.
\ Если результирующий файл становится больше, чем до операции,
\ часть файла, добавляемая в результате операции, может быть
\ не записана.
\ После завершения операции FILE-SIZE возвращает значение ud
\ и FILE-POSITION возвращает неопределенное значение.
  DUP >R REPOSITION-FILE  ?DUP IF RDROP EXIT THEN
  R> SetEndOfFile ERR
;

: WRITE-LINE ( c-addr u fileid -- ior ) \ 94 FILE
\ Записать u символов от c-addr с последующим зависящим от реализации концом 
\ строки в файл, идентифицируемый fileid, начиная с текущей позиции.
\ ior - определенный реализацией код результата ввода-вывода.
\ После завершения операции FILE-POSITION возвращает следующую
\ позицию в файле за последним записанным в файл символом, и
\ FILE-SIZE возвращает значение большее или равное значению,
\ возвращаемому FILE-POSITION.
  DUP >R WRITE-FILE ?DUP IF RDROP EXIT THEN
  EOLN R> WRITE-FILE
;

: FLUSH-FILE ( fileid -- ior ) \ 94 FILE EXT
  FlushFileBuffers ERR
;

\ TRUE если существует путь addr u
: FILE-EXIST ( addr u -- f )
  DROP GetFileAttributesA -1 <>
;

\ TRUE если путь addr u существует и не является каталогом
: FILE-EXISTS ( addr u -- f )
  DROP GetFileAttributesA INVERT 16 ( FILE_ATTRIBUTE_DIRECTORY) AND 0<>
;
