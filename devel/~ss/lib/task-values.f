(   
    Глобальные переменные потока. Обёртка Task Local Storage
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    В отличии от USER-VALUE в SPF4, содержимое ячеек TASK-VALUE 
  совпадает для всех вложенных CALLBACK: в текущем потоке.
    Либа написана под впечатлением ~af/lib/QuickWNDPROC.f
    Если task-values.f используется в SPF-DLL, то позаботьтесь
  об освобождении TLS в DLL_PROCESS_DETACH - вызовите FREE-TASK-VALUES.

  Шишминцев Сергей [mailto:ss@forth.org.ru]
  2006.02.23

  $Id$

  [1] Using Thread Local Storage  
      http://windowssdk.msdn.microsoft.com/library/en-us/dllproc/base/using_thread_local_storage.asp
)

WINAPI: TlsAlloc    KERNEL32.DLL
WINAPI: TlsFree     KERNEL32.DLL
WINAPI: TlsSetValue KERNEL32.DLL
WINAPI: TlsGetValue KERNEL32.DLL

: TLS-ALLOC ( -- index ior )
  TlsAlloc 
  DUP 0xFFFFFFFF = IF GetLastError ELSE 0 THEN  
;
: TLS-FREE ( index -- ior )
  TlsFree ERR
;

: TLS! ( x index -- ior )
  TlsSetValue ERR
;
: TLS@ ( index -- x ior )
  TlsGetValue 
  GetLastError 
;

: _TASK-VALUE-CODE
  R> @ TLS@ THROW
;
: _TOTASK-VALUE-CODE
  R> 5 - CELL- @ TLS! THROW
;
0 VALUE TASK-VALUES
: TASK-VALUE ( x "<spaces>name" -- ) 
  HEADER
  ['] _TASK-VALUE-CODE COMPILE, 
  TLS-ALLOC THROW DUP ,   \ index
      OVER SWAP TLS! THROW
  ['] _TOTASK-VALUE-CODE COMPILE,
    ,  \ начальное значения
  TASK-VALUES HERE TO TASK-VALUES
    ,  \ связанный список переменных
;

: INIT-TASK-VALUES
   \ выделяет память и устанавливет начальное значение для всех переменных.
  TASK-VALUES
  BEGIN DUP WHILE >R
    R@ CELL- @  \ S: default
    TLS-ALLOC THROW
    DUP
    R@ CELL- 5 - CELL- !  \ S: default index index
    TLS! THROW
  R> @ REPEAT DROP
;

: RESET-TASK-VALUES \ устанавливает начальное значение для всех переменных.
  TASK-VALUES
  BEGIN DUP WHILE >R
    R@ CELL- @  \ S: default
    R@ CELL- 5 - CELL- @  \ S: default index
    TLS! THROW
  R> @ REPEAT DROP
;

: FREE-TASK-VALUES \ свобождает TLS.
\  It is expected that DLLs call this [TlsFree] function 
\  (if at all) only during DLL_PROCESS_DETACH.  (from MSDN)
  TASK-VALUES
  BEGIN DUP WHILE
    DUP CELL- 5 - CELL- @  \ S: task-value index
    TLS-FREE THROW
  @ REPEAT DROP
;

WINAPI: GetCurrentThreadId KERNEL32.DLL
0 TASK-VALUE THREAD-ID 
GetCurrentThreadId TO THREAD-ID

..: AT-PROCESS-STARTING 
  INIT-TASK-VALUES 
  GetCurrentThreadId TO THREAD-ID 
;..

..: AT-THREAD-STARTING 
  THREAD-ID GetCurrentThreadId <> IF
    RESET-TASK-VALUES 
    GetCurrentThreadId TO THREAD-ID
  THEN
;..

\EOF
1000 TASK-VALUE TASK-HANDLER
INIT-TASK-VALUES  ( <- THREAD-ID обнулён!) THREAD-ID . 
GetCurrentThreadId TO THREAD-ID OK
TASK-HANDLER .
1024 TO TASK-HANDLER
TASK-HANDLER .
OK
:NONAME  TASK-HANDLER . ; CELL CALLBACK: test
0 ' test API-CALL DROP OK

:NONAME  
  0 ['] test API-CALL DROP
  1023 TO TASK-HANDLER
  0 ['] test API-CALL DROP
; TASK: task
WINAPI: WaitForSingleObject KERNEL32.DLL
0 task START -1 SWAP WaitForSingleObject DROP
OK
TASK-HANDLER . OK
BYE
0 Ok
1000 1024  Ok
1024  Ok
1000 1023  Ok
1024 Ok