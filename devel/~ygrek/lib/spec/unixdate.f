\ $Id$
\ unix timestamp в дату
\ и наоборот
\
\ URL в тему - http://vsg.cape.com/~pbaum/date/date0.htm

MODULE: FSL
 H-STDOUT
 0 TO H-STDOUT \ disable load-time output from FSL
 REQUIRE fsl-util ~diver/fsl-util.f
 REQUIRE JDAY ~clf/fsl/dates.seq
 TO H-STDOUT
;MODULE

REQUIRE [UNDEFINED] lib/include/tools.f
[UNDEFINED] WINAPI: [IF]
REQUIRE TZ ~ygrek/lib/linux/timezone.f
REQUIRE { lib/ext/locals.f
[THEN]

REQUIRE DateTime#GMT ~ac/lib/win/date/date-int.f
REQUIRE /TEST ~profit/lib/testing.f

\ Julian day начала эпохи unix 
: unix_epoch_j ( -- j_double ) 1 1 1970 FSL::JDAY ;

\ преобразовать timestamp в дату
: Num>DateTime ( n -- s m h d m1 y )
   60 /MOD \ секунды
   60 /MOD \ минуты
   24 /MOD \ часы
   S>D unix_epoch_j D+ FSL::JDATE ;

\ преобразовать дату в timestamp
: DateTime>Num ( s m h d m1 y -- n )
  FSL::JDAY unix_epoch_j D- D>S 60 60 * 24 * * SWAP
  3600 * + SWAP
  60 * + + ;

\ извлечь только время из timestamp
: Num>Time ( n -- s m h ) 60 /MOD 60 /MOD 24 /MOD DROP ;

\ дату в число дней
: DateTime>Days ( s m h d m1 y -- days ) FSL::JDAY D>S NIP NIP NIP ;

\ Представить дату как строку в буфере PAD
\ подразумевается GMT время
: DateTime>PAD ( s m h d m1 y -- a u ) <# DateTime#GMT 0 0 #> ;

\ convert timestamp with local time to timestamp with GMT time
: +TZ ( localtime -- gmtime ) TZ @ 60 * + ;

\ current date and time as unix timestamp (GMT)
: gmtime ( -- n ) TIME&DATE DateTime>Num +TZ ;

/TEST

REQUIRE TESTCASES ~ygrek/lib/testcase.f

TESTCASES timestamp-datetime conversions

(( unix_epoch_j -> 2440588 0 )) \ на самом деле 2440587.5
(( 1000000 Num>DateTime DateTime>Num -> 1000000 ))
(( 795792721 Num>DateTime -> 1 32 13 21 3 1995 ))
(( 1 32 13 21 3 1995 DateTime>Num -> 795792721 ))

END-TESTCASES
