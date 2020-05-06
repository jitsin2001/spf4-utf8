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

: (EXC) ( DispatcherContext ContextRecord EstablisherFrame ExceptionRecord -- flag )
  (ENTER) \ фрейм для стека данных
  \ 0 FS@ \ адрес последнего назначенного фрейма обработки исключений, EXCEPTION_REGISTRATION
  \ @ -- адрес следующего фрейма, или -1 если данный фрейм последний
  \ See-also: http://bytepointer.com/resources/pietrek_crash_course_depths_of_win32_seh.htm
  \   Matt Pietrek, "A Crash Course on the Depths of Win32™ Structured Exception HandlingЭ
  OVER \ EstablisherFrame - наш фрейм
  DUP 0 FS! \ восстанавливаем наш фрейм, чтобы продолжать ловить exceptions в будущем
  CELL+ CELL+ @ TlsIndex! \ ранее сохраненный указатель на USER-данные текущего потока

\  2DROP 2DROP
\  0 (LEAVE)               \ это если нужно передать обработку выше

  ( ExceptionRecord )
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

  ( ExceptionRecord )
  @ THROW  \ превращаем исключение в родное фортовое :)
  R> DROP   \ если все же добрались, то грамотно выходим из callback
;

: DROP-EXC-HANDLER
  R> 0 FS! RDROP RDROP
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
