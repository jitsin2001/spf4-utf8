\ SAVE a translation's error location for diagnostic  (SPF4 specific)
\ see ior codes in ~pinka/model/trans/trans.err


\ -----
\ Расширение (и исправление) штатного декодирования ошибок

\ Mar.2012 Убрана ненужная зависимость от STATE
\ (в spf/forthml биндилось не к тому STATE ;)

: I-NLIT ( addr u -- x true -- addr u false )
  I-LIT       IF TRUE EXIT THEN
  I-HLIT-FORM IF TRUE EXIT THEN
  FALSE
;

: /SYSTEM-PAD NUMERIC-OUTPUT-LENGTH ;

: (DECODE-ERROR?) ( n -- c-addr u true | n false )
  BEGIN
    REFILL
  WHILE ( n )
    PARSE-NAME I-NLIT 0= IF 2DROP FALSE EXIT ( bad file ) THEN
    OVER = IF ( n )
      DROP >IN 0! [CHAR] \ PARSE
      SYSTEM-PAD /SYSTEM-PAD SEATED
      TRUE EXIT
    THEN
  REPEAT ( n )
  FALSE
;
: DIAGNOSE ( ior -- addr u true | ior false )
  S" devel/~pinka/model/trans/trans.err" +ModuleDirName 
  2DUP FILE-EXIST 0= IF 2DROP FALSE EXIT THEN
  R/O OPEN-FILE-SHARED IF DROP FALSE EXIT THEN
  OVER >R 
    DUP >R
        ( n )
        ['] (DECODE-ERROR?) RECEIVE-WITH ( x ior | d-txt true 0 | n false 0 )
    R> CLOSE-FILE THROW
    IF DROP R> FALSE EXIT THEN
  RDROP
;

\ see also: spf/src/win/spf_win_envir.f # DECODE-ERROR

..: DECODE-ERROR ( ior u -- c-addr u )
  OVER DIAGNOSE IF 2NIP EXIT THEN DROP
;..




\ -----
\ Сохранение информации о месте ошибки трансляции


[UNDEFINED] CLEFT- [IF]
: CLEFT- ( a u cn -- a2 u2 )
  CHARS TUCK - >R + R>
;
[THEN]


XMLDOM-WL PUSH-SCOPE

: hint-node ( -- a u )
  cnode 0= IF 0. EXIT THEN
  cnode localName DUP IF cnode prefix NIP 0= IF EXIT THEN
    <# HOLDS `: HOLDS cnode prefix HOLDS 0. #>
    EXIT
  THEN 2DROP
  cnode nodeType TEXT_NODE <> IF cnode nodeName EXIT THEN
  cnode DUP >R parentNode cnode!
    RECURSE
  R> cnode!
  RCARBON
  <# cnode nodeValue 100 UMIN HOLDS S"  -- " HOLDS HOLDS S"   " HOLDS 0. #>
;
: line-number ( -- n )
  cnode 0= IF 0 EXIT THEN
  cnode nodeLineNumber DUP IF EXIT THEN DROP
  cnode parentNode nodeLineNumber
;

DROP-SCOPE


: SAVE-ERR-FML ( ior -- )
    ERR-DATA err.number !
  line-number
    ERR-DATA err.line# !
  0 ERR-DATA err.in#   !
  hint-node
    ERR-DATA err.line  /errstr_ 1 CLEFT- SEATED
  NIP
    ERR-DATA err.line C!   
  \ document-url  \ универсальный URL
  SOURCE-NAME     \ конкретный файл
    ERR-DATA err.file  /errstr_ 1 CLEFT- SEATED
  NIP
    ERR-DATA err.file C!   
  NOTSEEN-ERR
;
\ see also: spf/src/compiler/spf_error.f # SAVE-ERR


: SAVED-ERR-FML-SURE ( ior -- ior )
   DUP IF SEEN-ERR? IF DUP SAVE-ERR-FML THEN THEN
;

0 PUSH-WARNING

: EMBODY ( i*x url-a url-u -- j*x )
  CURFILE @ >R   2DUP translate-uri HEAP-COPY CURFILE ! \ for SOURCE-NAME
    ['] EMBODY CATCH
    DUP -5003 <> IF SAVED-ERR-FML-SURE THEN

  CURFILE @ FREE THROW   R> CURFILE !

    DUP -5003 =  IF SAVED-ERR-FML-SURE THEN
    \ в этом случае сохраняем место ошибки уже после отката CURFILE
    \ -- чтобы был правильный SOURCE-NAME в диагностике

    THROW
;
\ see also: spf/src/compiler/spf_translate.f # PROCESS-ERR

DROP-WARNING

