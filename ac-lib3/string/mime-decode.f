( rfc2231:

  charset := <registered character set name>
  language := <registered language tag [RFC-1766]>
  The ABNF given in RFC 2047 for encoded-words is:
  encoded-word := "=?" charset "?" encoding "?" encoded-text "?="
  This specification changes this ABNF to:
  encoded-word := "=?" charset ["*" language] "?" encoded-text "?="
  encoded-text = 1*<Any printable ASCII character other than "?" or SPACE>
                  ; but see "Use of encoded-words in message
                  ; headers", section 5


  rfc2045: base64, quotted printable
)

REQUIRE {             ~ac/lib/locals.f
REQUIRE "             ~ac/lib/str2.f
REQUIRE base64        ~ac/lib/string/conv.f
REQUIRE COMPARE-U     ~ac/lib/string/compare-u.f

VOCABULARY CHARSET-DECODERS 
GET-CURRENT ALSO CHARSET-DECODERS DEFINITIONS
: windows-1251 ;
: koi8-r KOI>WIN ;
: Koi8-r KOI>WIN ;
: KOI8-R KOI>WIN ;
GET-CURRENT
PREVIOUS SWAP SET-CURRENT CONSTANT CHARSET-DECODERS-WL

: dequotep ( addr u -- addr2 u2 ) { \ s c }
  "" -> s
  BASE @ >R HEX
  2DUP + >R DROP
  BEGIN
    DUP R@ <
  WHILE
    DUP C@ DUP [CHAR] = = 
        IF DROP 1+ DUP 2+ SWAP 2 0 0 2SWAP >NUMBER 2DROP D>S
           ?DUP IF -> c ^ c 1 s STR+ THEN
        ELSE -> c ^ c 1 s STR+ 1+ THEN
  REPEAT DROP R> DROP
  R> BASE ! s STR@
;
: MimeValueDecode1 ( encoding-a encoding-u text-a text-u flag -- addr u )
\ flag=true, если text закодирован base64
  IF debase64 ELSE dequotep THEN
  2SWAP CHARSET-DECODERS-WL SEARCH-WORDLIST IF EXECUTE THEN
;
: MimeValueDecode { addr u \ ta tu s b -- addr2 u2 }
  "" -> s
  BEGIN
    addr u S" =?" SEARCH
  WHILE
    -> tu -> ta
    addr ta OVER - s STR+                                  \ некодированный текст
    ta 2+ tu 2- S" ?" SEARCH 0= IF s STR+ s STR@ EXIT THEN \ ошибка encoder'а
    -> tu ta 2+ SWAP DUP -> ta OVER - \ encoding
    tu 5 < IF 2DROP ta tu s STR+ s STR@ EXIT THEN                \ ошибка encoder'а
    ta 3 S" ?B?" COMPARE-U 0= -> b
    ta 3 + tu 3 - S" ?=" SEARCH 0= IF s STR+ 2DROP s STR@ EXIT THEN
    2- -> u DUP 2+ -> addr
    ta 3 + SWAP OVER - \ text
    b MimeValueDecode1 s STR+
  REPEAT                                   \ остаток текста не кодирован
  s STR+ s STR@
;
: StripLwsp1 { \ s }
  "" -> s
  BEGIN
    13 PARSE DUP
  WHILE
    s STR+
    SOURCE DROP >IN @ + 1+ C@ IsDelimiter IF 2 >IN +! THEN
  REPEAT 2DROP
  s STR@
;
: StripLwsp ( addr u -- addr2 u2 )
\ убрать из текста заголовка символы CRLFLWSP
\ т.е. переводы строк с последующими пробельными
\ символами, означающие перенос длинной строки
  ['] StripLwsp1 EVALUATE-WITH
;

(
" Subject: =?windows-1251?B?UmU6IFtlc2Vydl0gze7i++kg8ffl8iBFLTE5NDEg7vIgMjguMDEuMg==?=
	=?windows-1251?B?MDAz?=
Subject: =?koi8-r?B?W0V0eXBlXSDJzsbP0s3Bw8nRIM8g0MXSxdLZ18Ug09fR2skgMTUg0c7XwdLR?=
Subject: =?Windows-1251?B?0SDN7uL77CDD7uTu7CEg1e7y/CDxIO7v4Ofk4O3o5ewsIO3uIOLx5SDm?=
	=?Windows-1251?B?5SAlKQ==?=
From: =?koi8-r?Q?=EF=CC=D8=C7=C1=20=F0=C1=D7=CC=CF=D7=C1?=
Subject: =?koi8-r?Q?RE:_FIG_Taiwan_+_Russian+_clf_=C4=CF_=CB=D5=DE=C9?=
Subject: =?windows-1251?Q?=EF=EE_=EF=EE=E2=EE=E4=F3_Eserv?=
" STR@ StripLwsp MimeValueDecode ANSI>OEM TYPE
)
