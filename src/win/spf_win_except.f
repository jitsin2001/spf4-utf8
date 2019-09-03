\ $Id$

( Обработка аппаратных исключений [деление на ноль, обращение
  по недопустимым адресам, и т.д.] - путем перевода в THROW.
  Copyright [C] 1992-1999 A.Cherezov ac@forth.org
  Cентябрь 1999
)

   H-STDIN  VALUE  H-STDIN    \ хэндл файла - стандартного ввода
   H-STDOUT VALUE  H-STDOUT   \ хэндл файла - стандартного вывода
   H-STDERR VALUE  H-STDERR   \ хэндл файла - стандартного вывода ошибок
          0 VALUE  H-STDLOG


: AT-THREAD-FINISHING ( -- ) ... ;
: AT-PROCESS-FINISHING ( -- ) ... DESTROY-HEAP ;

: HALT ( ERRNUM -> ) \ выход с кодом ошибки
  AT-THREAD-FINISHING
  AT-PROCESS-FINISHING
  ExitProcess
;

USER EXC-HANDLER  \ аппаратные исключения (преобразуемые в программные)

( DispatcherContext ContextRecord EstablisherFrame ExceptionRecord ExceptionRecord --
  DispatcherContext ContextRecord EstablisherFrame ExceptionRecord )
VECT <EXC-DUMP> \ действия по обработке исключения

: DROP-EXC-HANDLER
  R> 0 FS! RDROP RDROP
;

: (EXC) ( DispatcherContext ContextRecord EstablisherFrame ExceptionRecord -- flag )
  (ENTER) \ фрейм для стека данных
  0 FS@ \ адрес последнего назначенного фрейма обработки исключений
  \ ищем в цепочке фреймов наш фрейм (по "метке", -- возможно, есть лучший способ?)
  BEGIN DUP WHILE DUP -1 <> WHILE DUP CELL- @ ['] DROP-EXC-HANDLER <> WHILE ( ." alien " ) @ REPEAT THEN THEN
  \ Цепочка завершается ссылкой на -1
  DUP 0= OVER -1 = OR IF 0 TlsIndex! S" ERROR: EXC-frame not found " TYPE -1 ExitThread THEN
  \ Шанс, что свой фрейм не найдем, весьма мал -- т.к. управление в (EXC) попадает только через этот фрейм.
  DUP 0 FS! \ восстанавливаем наш фрейм, чтобы продолжать ловить exceptions в будущем
  CELL+ CELL+ @ TlsIndex! \ ранее сохраненный указатель на USER-данные текущего потока

\  2DROP 2DROP
\  0 (LEAVE)               \ это если нужно передать обработку выше

  DUP @ 0xC000013A = IF \ CONTROL_C_EXIT - Ctrl+C on wine
    0xC000013A HALT
  THEN
  DUP <EXC-DUMP>

  HANDLER @ 0=
  IF \ исключение в потоке, без CATCH, выдаем отчет и завершаем (~day)
     DESTROY-HEAP
     -1 ExitThread
  THEN

  FINIT \ если float исключение, восстанавливаем

  @ THROW  \ превращаем исключение в родное фортовое :)
  R> DROP   \ если все же добрались, то грамотно выходим из callback
;

: SET-EXC-HANDLER
  R> R>
  TlsIndex@ >R
  ['] (EXC) >R
  0 FS@ >R
  RP@ 0 FS!
  RP@ EXC-HANDLER !
  ['] DROP-EXC-HANDLER >R \ самоубираемый фрейм ловли аппаратн.исключения
  >R >R
;
' SET-EXC-HANDLER ' <SET-EXC-HANDLER> TC-VECT!
