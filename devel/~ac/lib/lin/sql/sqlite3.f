( ~ac: 23.08.2005 перенесено из ~ac/lib/win/odbc/sqlite3.f 
   для переопределения через "SO NEW", без WINAPI.
   
  $Id$
)

WARNING @ WARNING 0!
REQUIRE SO            ~ac/lib/ns/so-xt.f
REQUIRE STR@          ~ac/lib/str5.f
REQUIRE COMPARE-U     ~ac/lib/string/compare-u.f
WARNING !

REQUIRE [IF]          lib/include/tools.f
REQUIRE ms@           lib/include/facil.f

ALSO SO NEW: sqlite3.dll
ALSO SO NEW: libsqlite3.so.0
ALSO SO NEW: /usr/local/lib/libsqlite3.so

  0 CONSTANT SQLITE_STATIC
  5 CONSTANT SQLITE_BUSY
100 CONSTANT SQLITE_ROW
    VARIABLE DB3_DEBUG
    VARIABLE DB3_MAX_WAIT       1000 DB3_MAX_WAIT !
    USER     DB3_CONN_CNT
    USER     DB3_STMT_CNT

(
#define SQLITE_OK           0   /* Successful result */
#define SQLITE_ERROR        1   /* SQL error or missing database */
#define SQLITE_INTERNAL     2   /* An internal logic error in SQLite */
#define SQLITE_PERM         3   /* Access permission denied */
#define SQLITE_ABORT        4   /* Callback routine requested an abort */
#define SQLITE_BUSY         5   /* The database file is locked */
#define SQLITE_LOCKED       6   /* A table in the database is locked */
#define SQLITE_NOMEM        7   /* A malloc[] failed */
#define SQLITE_READONLY     8   /* Attempt to write a readonly database */
#define SQLITE_INTERRUPT    9   /* Operation terminated by sqlite_interrupt[] */
#define SQLITE_IOERR       10   /* Some kind of disk I/O error occurred */
#define SQLITE_CORRUPT     11   /* The database disk image is malformed */
#define SQLITE_NOTFOUND    12   /* [Internal Only] Table or record not found */
#define SQLITE_FULL        13   /* Insertion failed because database is full */
#define SQLITE_CANTOPEN    14   /* Unable to open the database file */
#define SQLITE_PROTOCOL    15   /* Database lock protocol error */
#define SQLITE_EMPTY       16   /* [Internal Only] Database table is empty */
#define SQLITE_SCHEMA      17   /* The database schema changed */
#define SQLITE_TOOBIG      18   /* Too much data for one row of a table */
#define SQLITE_CONSTRAINT  19   /* Abort due to constraint violation */
#define SQLITE_MISMATCH    20   /* Data type mismatch */
#define SQLITE_MISUSE      21   /* Library used incorrectly */
#define SQLITE_NOLFS       22   /* Uses OS features not supported on host */
#define SQLITE_AUTH        23   /* Authorization denied */
#define SQLITE_FORMAT      24   /* Auxiliary database format error */
#define SQLITE_RANGE       25   /* 2nd parameter to sqlite_bind out of range */
#define 	SQLITE_NOTADB   26
#define SQLITE_ROW         100  /* sqlite_step[] has another row ready */
#define SQLITE_DONE        101  /* sqlite_step[] has finished executing */

#define SQLITE_INTEGER  1
#define SQLITE_FLOAT    2
#define SQLITE_TEXT     3
#define SQLITE_BLOB     4
#define SQLITE_NULL     5
)

: db3_error? { ior addr u sqh -- }
  ior IF DB3_DEBUG @ IF CR addr u TYPE ."  failed: " ior . THEN
         sqh 1 sqlite3_errmsg ASCIIZ> DB3_DEBUG @ IF 2DUP TYPE CR THEN
         " {s}" STR@ ER-U ! ER-A !
         sqh 1 sqlite3_errcode DUP 1 = IF DROP -2 ELSE 30000 + THEN ( ior )
	 DUP 30000 = IF DROP EXIT THEN \ и sqlite3_errmsg говорит "not an error"
         THROW
      THEN
\  ior THROW ( ior почти всегда 1 в случае ошибки)
;
: (db3_version) ( -- n ) \ например 3006003
  0 sqlite3_libversion_number
;
: db3_version ( -- n ) \ возвратит номер версии или -2010, если dll нет
  ['] (db3_version) CATCH DUP 0= IF DROP THEN
;
: db3_version_str ( -- addr u )
  0 sqlite3_libversion ASCIIZ>
;
: db3_used_memory { \ cur hw -- cur hw }
  0 ^ hw ^ cur 0 ( SQLITE_STATUS_MEMORY_USED) 4 sqlite3_status THROW cur hw
;
: db3_open { addr u \ sqh -- sqh }
\  TRUE 1 sqlite3_enable_shared_cache THROW \ Cannot use virtual tables in shared-cache mode
  ^ sqh addr 2 sqlite3_open S" DB3_OPEN" sqh db3_error? sqh
  DB3_CONN_CNT 1+!
\  TRUE OVER 2 sqlite3_extended_result_codes DROP
  DB3_DEBUG @ IF CR ." DB3_OPEN====================" sqh . CR addr u TYPE CR THEN
;
: db3_close { sqh -- }
  sqh 0= IF DB3_DEBUG @ IF CR ." DB3_CLOSE_0============" CR CR THEN EXIT THEN
  sqh 1 sqlite3_close S" DB3_CLOSE" sqh db3_error?
  DB3_CONN_CNT @ 1- DB3_CONN_CNT !
  DB3_DEBUG @ IF CR ." DB3_CLOSE====================" sqh . CR CR THEN
;
: db3_cols ( ppStmt -- n )
  1 sqlite3_column_count
;
: db3_colname ( n ppStmt -- addr u )
  2 sqlite3_column_name ?DUP IF ASCIIZ> ELSE S" (UNKNOWN)" THEN
;
: db3_colsize ( n ppStmt -- u )
  2 sqlite3_column_bytes
;
: db3_col ( n ppStmt -- addr u )
  2 sqlite3_column_text ?DUP IF ASCIIZ> ELSE S" NULL" THEN
;
: db3_colu ( n ppStmt -- addr u )
  2DUP 2>R
  2 sqlite3_column_text 
  2R> db3_colsize
;
: db3_coli ( n ppStmt -- int )
  2 sqlite3_column_int
;
: db3_coli64 ( n ppStmt -- d ) \ результат в формате для "D."
  2 sqlite3_column_int64 _C-EXEC-HW @
;
: db3_field_num { addr1 u1 ppStmt -- n } \ номер поля с заданным именем
  ppStmt db3_cols 0 ?DO
    I ppStmt db3_colname addr1 u1 COMPARE-U 0=
    IF I UNLOOP EXIT THEN
  LOOP -1
;
: db3_field { addr1 u1 ppStmt -- addr u }
  addr1 u1 ppStmt db3_field_num DUP 0< IF DROP S" " ELSE ppStmt db3_col THEN
;
: db3_fieldu { addr1 u1 ppStmt -- addr u }
  addr1 u1 ppStmt db3_field_num DUP 0< IF DROP S" " ELSE ppStmt db3_colu THEN
;
: db3_fieldi { addr1 u1 ppStmt -- int }
  addr1 u1 ppStmt db3_field_num DUP 0< IF DROP 0 ELSE ppStmt db3_coli THEN
;
: db3_coltype ( n ppStmt -- n )
  2 sqlite3_column_type
;
: sqlite3_prepare1
\  db3_version 3005000 < IF sqlite3_prepare ELSE sqlite3_prepare_v2 THEN
  sqlite3_prepare_v2
;
: sqlite3_prepare2
  ['] sqlite3_prepare1 CATCH
  ?DUP IF NIP NIP NIP NIP NIP NIP THEN \ добавим аппаратные exceptions в коды возврата
;
: db3_prepare { addr u sqh \ pzTail ppStmt waitcnt -- pzTail ppStmt }
  DB3_DEBUG @ IF CR ." DB3_PREP====================" sqh . CR addr u TYPE CR THEN

  BEGIN \ ждем освобождения доступа к БД
    ^ pzTail ^ ppStmt u addr sqh 5 sqlite3_prepare2 DUP SQLITE_BUSY = \ waitcnt DB3_MAX_WAIT @ < AND
  WHILE
    DB3_DEBUG @ IF ." DB3_PREP_WAIT" ppStmt . THEN
    DROP 100 PAUSE \ ^ waitcnt 1+!
  REPEAT
  \ waitcnt DB3_MAX_WAIT @ = IF ." db3_prepare:maxwait:" addr u TYPE CR 30114 THROW THEN

  S" DB3_PREPARE" sqh db3_error?
  ppStmt
  0= IF 30112 THROW THEN \ при подаче пустой команды sqlite не возвращает
                         \ код ошибки, но и ppStmt оставляет нулевым,
                         \ что в дальнейшем приводит к exception
  pzTail ppStmt
  DB3_DEBUG @ IF CR ." DB3_PREP_OK====================" sqh . CR THEN
  DB3_STMT_CNT 1+!
;
: db3_bind { ppStmt -- }
  ppStmt 1 sqlite3_bind_parameter_count 0 ?DO
    I 1+ ppStmt 2 sqlite3_bind_parameter_name
    ?DUP 
    IF ASCIIZ> SFIND
       IF SQLITE_STATIC SWAP EXECUTE SWAP I 1+ ppStmt 5 sqlite3_bind_text THROW
       ELSE 1- SWAP 1+ SWAP SFIND
            IF SQLITE_STATIC SWAP EXECUTE SWAP I 1+ ppStmt 5 sqlite3_bind_text THROW
            ELSE TYPE ."  - bind name not found" THEN
       THEN
    THEN
  LOOP
;
: db3_reset ( ppStmt -- )
  1 sqlite3_reset THROW
;
: db3_ubind ( ppStmt -- )
  1 sqlite3_clear_bindings THROW
;
: db3_fin ( ppStmt -- )
  DUP db3_reset
  DUP db3_ubind
      1 sqlite3_finalize THROW
  DB3_STMT_CNT @ 1- DB3_STMT_CNT !
;
USER db3_exec_CNT
USER db3_exec_TICKS

: db3_exec { addr u par xt sqh \ pzTail ppStmt i tick waitcnt -- }
\ выполнить SQL-запрос(ы) из addr u,
\ вызывая для каждого результата функцию xt с параметрами i par ppStmt
\ в запросах биндятся макроподстановки :name и $name
  u 0= IF EXIT THEN
  sqh 0= IF ." Sqh=0; db3_exec=" addr u TYPE CR EXIT THEN
  db3_exec_CNT 1+! ms@ -> tick
  BEGIN
    addr u sqh db3_prepare -> ppStmt -> pzTail
    addr u + C@ 0<> IF ." DB3 command corrupted (prepare). [" addr u TYPE ." ]" CR THEN
    ppStmt db3_bind

    TRUE 0 -> i
    BEGIN
      IF
        BEGIN \ ждем освобождения доступа к БД
          ppStmt 1 sqlite3_step DUP SQLITE_BUSY = \ waitcnt DB3_MAX_WAIT @ < AND
        WHILE
          DB3_DEBUG @ IF CR ." DB3_STEP_WAIT(" sqh . ppStmt . addr u TYPE ." )" CR THEN
          DROP 100 PAUSE \ ^ waitcnt 1+!
        REPEAT
        \ waitcnt DB3_MAX_WAIT @ = IF ." db3_exec:maxwait:" addr u TYPE CR 30114 THROW THEN
        addr u + C@ 0<> IF ." DB3 command corrupted (step)." CR THEN

        DUP 1 SQLITE_ROW WITHIN 
        IF ppStmt ['] db3_fin CATCH ?DUP IF NIP NIP DB3_DEBUG @ IF ." DB3_FIN_failed" DUP . THEN THEN 
           DUP DB3_DEBUG @ AND IF ." DB3_STEP_failed (" addr u TYPE ." )" THEN
           S" DB3_STEP" sqh db3_error?
        THEN

        SQLITE_ROW =
      ELSE FALSE THEN
    WHILE
      i 1+ -> i
      i par ppStmt xt EXECUTE \ возвращает флаг продолжения
      addr u + C@ 0<> IF ." DB3 command corrupted (execute)." CR THEN
    REPEAT

    DB3_DEBUG @
    IF ." DB3_STATS:" ppStmt . ms@ tick - .
       1 1 ppStmt 3 sqlite3_stmt_status .    \ SQLITE_STMTSTATUS_FULLSCAN_STEP
       1 2 ppStmt 3 sqlite3_stmt_status .    \ SQLITE_STMTSTATUS_SORT
       1 3 ppStmt 3 sqlite3_stmt_status . CR \ SQLITE_STMTSTATUS_AUTOINDEX
    THEN

    ppStmt db3_fin
    addr u + C@ 0<> IF ." DB3 command corrupted (fin)." CR THEN
    pzTail ?DUP IF 
                   addr u + C@ 0<> 
                   IF . DROP " DB3 command corrupted (tail)." CR S" "
                   ELSE
                     DUP addr u OVER + 1+ WITHIN 0=
                     IF DROP ." DB3 comand tail isn't in range." CR S" "
                     ELSE ASCIIZ> THEN
                   THEN
                ELSE S" " THEN
                -> u -> addr
  u 3 < UNTIL
  ms@ tick - db3_exec_TICKS +!
;
: 3DROP0 2DROP DROP 0 ;

: db3_exec_ { addr u sqh \ res -- }
  \ упрощенная форма вызова exec для CREATE, INSERT и т.п.
  addr u ^ res ['] 3DROP0 sqh db3_exec
;
: db3_insert_id ( sqh -- id ) \ ROWID, OID, or _ROWID_
  \ id первичного ключа последней вставки
  \ если еще ничего не вставлялось, то 0
  1 sqlite3_last_insert_rowid
;
: (db3_cdr) { ppStmt \ waitcnt -- ppStmt | 0 }
  BEGIN \ ждем освобождения доступа к БД
    ppStmt 1 sqlite3_step DUP SQLITE_BUSY = \ waitcnt DB3_MAX_WAIT @ < AND
  WHILE
    DB3_DEBUG @ IF ." DB3_CDR_WAIT" ppStmt . THEN
    DROP 100 PAUSE \ ^ waitcnt 1+!
  REPEAT
  \ waitcnt DB3_MAX_WAIT @ = IF ." db3_cdr:maxwait" CR 30114 THROW THEN

  DUP 1 SQLITE_ROW WITHIN ABORT" DB3_STEP error"

  SQLITE_ROW = IF ppStmt ELSE ( ppStmt db3_fin) 0 THEN
;
: db3_cdr { ppStmt -- ppStmt | 0 }
  ppStmt (db3_cdr) DUP 0= IF ppStmt db3_fin THEN
;
: db3_car ( addr u sqh -- ppStmt )
  db3_prepare NIP DUP db3_bind db3_cdr
;
: db3_enum { addr u par xt sqh \ i -- }
\ выполнить SQL-запрос из addr u,
\ вызывая для каждого результата функцию xt с параметрами i par ppStmt
\ в запросах биндятся макроподстановки :name и $name
  sqh 0= IF ." Sqh=0; db3_enum=" addr u TYPE CR EXIT THEN
  addr u sqh db3_car ?DUP
  IF
    0 -> i
    BEGIN
      DUP
    WHILE
      DUP
      i 1+ -> i
      i par ROT xt EXECUTE \ возвращает флаг продолжения
      IF db3_cdr ELSE db3_fin 0 THEN
    REPEAT DROP
  THEN
;
: db3_dump1 { i par ppStmt -- flag }
  i 1 =
  IF
    ppStmt db3_cols 0 ?DO
      I ppStmt db3_colname [CHAR] " EMIT TYPE [CHAR] " EMIT ." ;"
    LOOP CR
  THEN
  ppStmt db3_cols 0 ?DO
    I ppStmt db3_col     [CHAR] " EMIT TYPE [CHAR] " EMIT ." ;"
  LOOP CR TRUE
;
: db3_dump { par ppStmt \ i -- }
  0 -> i
  BEGIN
    i 1+ -> i
    i par ppStmt db3_dump1 DROP
    ppStmt db3_cdr DUP -> ppStmt 0=
  UNTIL
;

USER _db3_get_1
USER _db3_get_2
USER _db3_get_3
USER _db3_gets
USER _db3_get_64 4 USER-ALLOT

: db3_get_id1_ { i par ppStmt -- flag }
  0 ppStmt db3_coli _db3_get_1 ! 
  FALSE
;
: db3_get_id1 ( addr u sqh -- id1 )
  _db3_get_1 0!
  >R 0 ['] db3_get_id1_ R> db3_exec
  _db3_get_1 @
;
: db3_get_id2_ { i par ppStmt -- flag }
  0 ppStmt db3_coli _db3_get_1 ! 
  1 ppStmt db3_coli _db3_get_2 ! 
  FALSE
;
: db3_get_id2 ( addr u sqh -- id1 id2 )
  _db3_get_1 0! _db3_get_2 0!
  >R 0 ['] db3_get_id2_ R> db3_exec
  _db3_get_1 @ _db3_get_2 @
;
: db3_get_id3_ { i par ppStmt -- flag }
  0 ppStmt db3_coli _db3_get_1 ! 
  1 ppStmt db3_coli _db3_get_2 ! 
  2 ppStmt db3_coli _db3_get_3 ! 
  FALSE
;
: db3_get_id3 ( addr u sqh -- id1 id2 id3 )
  _db3_get_1 0! _db3_get_2 0! _db3_get_3 0!
  >R 0 ['] db3_get_id3_ R> db3_exec
  _db3_get_1 @ _db3_get_2 @ _db3_get_3 @
;
: db3_gets_ { i par ppStmt -- flag }
  0 ppStmt db3_col _db3_gets S! 
  FALSE
;
: db3_gets ( addr u sqh -- addr u )
  _db3_gets 0!
  >R 0 ['] db3_gets_ R> db3_exec
  _db3_gets @ ?DUP IF STR@ ELSE S" " THEN
;
: db3_getsu_ { i par ppStmt -- flag }
  0 ppStmt db3_colu _db3_gets S! 
  FALSE
;
: db3_getsu ( addr u sqh -- addr u )
  _db3_gets 0!
  >R 0 ['] db3_getsu_ R> db3_exec
  _db3_gets @ ?DUP IF STR@ ELSE S" " THEN
;
: db3_gets_id_ { i par ppStmt -- flag }
  0 ppStmt db3_colu _db3_gets S! 
  1 ppStmt db3_coli _db3_get_1 ! 
  FALSE
;
: db3_gets_id ( addr u sqh -- addr u id )
  _db3_gets 0! _db3_get_1 0!
  >R 0 ['] db3_gets_id_ R> db3_exec
  _db3_gets @ ?DUP IF STR@ ELSE S" " THEN
  _db3_get_1 @
;
: db3_get_id64_ { i par ppStmt -- flag }
  0 ppStmt db3_coli64 _db3_get_64 2! 
  FALSE
;
: db3_get_id64 ( addr u sqh -- d )
  0 0 _db3_get_64 2!
  >R 0 ['] db3_get_id64_ R> db3_exec
  _db3_get_64 2@
;
: db3_thread_cleanup ( -- )
\  1 1 sqlite3_soft_heap_limit DROP \ недоступно
  0 sqlite3_thread_cleanup DROP     \ ничего не делает...
;
: (db3_enable_extensions) ( sqh -- )
  TRUE SWAP 2 sqlite3_enable_load_extension DROP
;
: db3_enable_extensions ( sqh -- ) \ попадаются .so без расширений
  ['] (db3_enable_extensions) CATCH IF ." can't enable sqlite extensions" CR DROP THEN
;
: db3_changes ( sqh -- n ) 1 sqlite3_changes ; \ for ~dandy

: db3_table_col_type { cnamea cnameu tnamea tnameu sqh \ ai pk nn cs dt -- typea typeu }
\ возвращает тип заданного поля заданной таблицы (не view!) в открытой БД
  ^ ai ^ pk ^ nn ^ cs ^ dt cnamea tnamea 0 sqh 9 sqlite3_table_column_metadata DROP
  dt ?DUP IF ASCIIZ> ELSE S" " THEN
;
: db3_checkpoint ( sqh -- )
  0 SWAP 2 sqlite3_wal_checkpoint DROP
;
: db3_checkpoint_all ( sqh -- )
  >R
  0 0 2 \ restart
  0 R>
  5 sqlite3_wal_checkpoint_v2 DROP
;
: db3_shared_cache ( -- )
  1 1 sqlite3_enable_shared_cache DROP
;
: (db3_backup_to) { addr u sqh \ sd b -- }
\ записать копию БД из хэндла sqh в db3-файл с именем addr u
  addr u db3_open -> sd
  S" main" DROP sqh S" main" DROP sd 4 sqlite3_backup_init -> b
  b 0= IF 5 S" sqlite3_backup_init" sd db3_error? THEN

  BEGIN \ ждем освобождения доступа к БД
    -1 b 2 sqlite3_backup_step 
    DUP SQLITE_BUSY =
  WHILE
    DB3_DEBUG @ IF ." DB3_BACKUP_WAIT" b . THEN
    DROP 100 PAUSE \ ^ waitcnt 1+!
  REPEAT
  101 ( SQLITE_DONE ) <> 
  IF
    b 1 sqlite3_backup_finish DROP
    5 S" sqlite3_backup_step" sd ['] db3_error? CATCH
    sd db3_close
    THROW
  THEN
  b 1 sqlite3_backup_finish
  ?DUP IF S" sqlite3_backup_finish" sd db3_error? THEN
  sd db3_close
;
: db3_backup_to { addr u sqh \ sd b -- }
  addr u sqh ['] (db3_backup_to) CATCH ?DUP
  IF NIP NIP NIP
     ." db3_backup failed: " DUP . addr u TYPE CR
     30008 = \ запись в read-only БД или несоответствие page_size (в новых sqlite изменили с 1К на 4К)
     IF addr u DELETE-FILE ." deleted: " . CR
	addr u sqh ['] (db3_backup_to) CATCH ?DUP
        IF ." second attempt failed too: " . CR DROP 2DROP THEN
     THEN
  THEN
;
PREVIOUS PREVIOUS PREVIOUS

: '>` ( addr u -- )
  0 ?DO DUP C@ [CHAR] ' = IF [CHAR] ` OVER C! THEN 1+ LOOP DROP
;
: `? ( addr1 u1 -- addr2 u2 )
  2DUP S" '" SEARCH NIP NIP IF " {s}" STR@ 2DUP '>` THEN
;


\EOF примеры:
: kl \ можно подставлять в SQL-команду как :kl или $kl для авто-биндинга
  S" Kalinin%"
;
: kldump { i par ppStmt -- flag }
  S" Population" 2DUP TYPE ." =" ppStmt db3_fieldi .
  FALSE
;
: TEST { \ sqh }
  S" \spf4\devel\~ac\lib\ns\world.db3" db3_open -> sqh
  S" select id, 5 from City where name like :kl" sqh db3_get_id2 2DUP . . DROP CR
  DUP " select * from City where id={n}" STR@ 0 ['] db3_dump1 sqh db3_enum
  DUP " select * from City where id={n}" STR@ 0 ['] kldump sqh db3_enum
  " update City set Population=Population+1 where id={n}" STR@ sqh db3_exec_ sqh db3_changes ." +" .
  sqh db3_close
; TEST
\EOF примеры:
: TEST { \ sqh }
  S" \spf4\devel\~ac\lib\ns\world.db3" db3_open -> sqh
  S" select id, 5 from City where name like 'Kalinin%'" sqh db3_get_id2 . .
  sqh db3_close
; TEST
\EOF
: TEST { \ sqh }
  S" test.db3" db3_open -> sqh
  S" CREATE TABLE Items (ID INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT);begin"
  sqh db3_exec_
  sqh db3_insert_id .
  S" INSERT INTO Items (Name) VALUES ('Тест1')" sqh db3_exec_
  sqh db3_insert_id .
  S" INSERT INTO Items (Name) VALUES ('Тест2');commit" sqh db3_exec_
  sqh db3_insert_id .
  sqh db3_close
; TEST

\EOF

: TEST2 { \ sqh res }
  S" world.db3" db3_open -> sqh
  S" SELECT * FROM Country WHERE CODE LIKE 'RU%' ORDER BY CODE2" ^ res ['] db3_dump1 sqh db3_enum
  sqh db3_close
; TEST2

\ S" :memory:" db3_open .

: $CO S" RU" ;

\ S" D:\Program Files\SQLiteSpy_1.1\world.db3" db3_open
\ ' db3_dump OVER S" SELECT * FROM Country" 2SWAP 555 ROT ROT db3_exec
\ db3_close

: TEST1 { i par ppStmt -- flag }
  S" CODE2" ppStmt db3_field 2DUP TYPE SPACE
  S" name" ppStmt db3_field TYPE CR
  S" RU" COMPARE
;
: TEST { \ sqh res }
\  S" C:\ac\dl\SQLiteSpy_1.1\world.db3" db3_open -> sqh
  S" D:\Program Files\SQLiteSpy_1.1\world.db3" db3_open -> sqh
  S" SELECT * FROM Country ORDER BY CODE2" ^ res ['] TEST1 sqh db3_exec
  sqh db3_close
;

(
: TEST { \ sqh res }
  S" dbmail.db3" db3_open -> sqh
  S" dbmail.sql" FILE ^ res ['] db3_dump1 sqh db3_exec
  sqh db3_close
;
: TEST2 { \ sqh res }
  S" world.db3" db3_open -> sqh
  S" SELECT * FROM Country ORDER BY CODE2" ^ res ['] db3_dump1 sqh db3_enum
  sqh db3_close
; TEST2
)
