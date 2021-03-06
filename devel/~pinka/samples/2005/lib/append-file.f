\ 09.Dec.2004
\ $Id$

REQUIRE [DEFINED] lib/include/tools.f

: 9REPOSITION-FILE ( fileid -- ior )
\ Reposition the file identified by fileid to end of file.
\ see also  ~pinka\lib\FileExt.f # TOEND-FILE
  DUP >R   FILE-SIZE  ( fileid -- ud ior ) 
  ?DUP IF R> DROP NIP NIP EXIT THEN
  R> REPOSITION-FILE  ( ud fileid -- ior ) 
;

[DEFINED] OPEN-FILE-SHARED-DELETE [IF] \ see ~ac/lib/win/file/share-delete.f

: OPEN-LOGFILE ( a u -- h ior )
  2DUP FILE-EXIST 0= IF W/O CREATE-FILE-SHARED-DELETE EXIT THEN
  W/O OPEN-FILE-SHARED-DELETE DUP IF EXIT THEN DROP ( h )
  DUP 9REPOSITION-FILE DUP 0= IF EXIT THEN ( h ior )
  SWAP CLOSE-FILE DROP ( ior ) 0 SWAP ( 0 ior )
;
[ELSE]

: OPEN-LOGFILE ( a u -- h ior )
  2DUP FILE-EXIST 0= IF W/O CREATE-FILE-SHARED EXIT THEN
  W/O OPEN-FILE-SHARED DUP IF EXIT THEN DROP ( h )
  DUP 9REPOSITION-FILE DUP 0= IF EXIT THEN ( h ior )
  SWAP CLOSE-FILE DROP ( ior ) 0 SWAP ( 0 ior )
;

\ Вариант:
\ OPEN-FILE-LOG ( a u fam -- h ior )
\ -- хорошо согласуется по сигнатуре с другими OPEN-FILE-* 
[THEN]


: OPEN-LOG ( a u -- h )
  OPEN-LOGFILE THROW
;
: ATTACH-CATCH ( a u a-file u-file -- ior )
  OPEN-LOGFILE DUP IF NIP NIP EXIT THEN DROP
  DUP >R WRITE-FILE ( ior )
  R> CLOSE-FILE ( ior ior2 ) OVER IF DROP EXIT THEN NIP
;
: ATTACH ( a u a-file u-file -- )
  ATTACH-CATCH THROW
;
: ATTACH-LINE ( a u a-file u-file -- )
  OPEN-LOGFILE THROW
  DUP >R WRITE-FILE  LT LTL @ R@ WRITE-FILE
  R> CLOSE-FILE  SWAP THROW THROW THROW
;
: ATTACH-LINE-CATCH ( a u a-file u-file -- ior )
  ['] ATTACH-LINE CATCH
  DUP IF NIP NIP NIP NIP THEN
;
\ : OCCUPY ( a u a-file u-file -- )
\   2DUP FILE-EXIST IF 2DUP DELETE-FILE THROW THEN ATTACH
\ ;
: EMPTY ( file-a file-u -- )
  2DUP FILE-EXIST 0= IF 2DROP EXIT THEN
  W/O OPEN-FILE THROW
  DUP 0. ROT RESIZE-FILE ( h ior )
  SWAP CLOSE-FILE SWAP THROW THROW
;
: OCCUPY ( a u a-file u-file -- )
  2DUP EMPTY ATTACH
;
: OCCUPY-CATCH ( a u a-file u-file -- ior )
  ['] OCCUPY CATCH DUP IF >R 2DROP 2DROP R> THEN
;
