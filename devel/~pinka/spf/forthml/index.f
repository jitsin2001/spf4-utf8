\ 18.Feb.2007
\ $Id$
( Транслятор ForthML [как расширение к SPF4]

Использование
  S" url-of.f.xml" EMBODY [ i*x c-addrz u -- j*x ]
  -- создает объект по указанной модели в текущем контексте


Ограничения
  -- пока транслятор не многопоточен.
)


REQUIRE [UNDEFINED]     lib/include/tools.f
REQUIRE AsQName         ~pinka/samples/2006/syntax/qname.f \ понятие однословных строк в виде `abc
REQUIRE CORE_OF_REFILL  ~pinka/spf/fix-refill.f
REQUIRE SET-STDOUT      ~pinka/spf/stdio.f
REQUIRE Require         ~pinka/lib/ext/requ.f
REQUIRE AT-SAVING-BEFORE ~pinka/spf/storage.f
REQUIRE WITHIN-FORTH-STORAGE-EXCLUSIVE  ~pinka/spf/storage-sync.f
REQUIRE RCARBON         ~pinka/spf/rbuf.f

REQUIRE lexicon.basics-aligned ~pinka/lib/ext/basics.f

[UNDEFINED] XCOUNT [IF] \ for backward compatibility
: XCOUNT ( xaddr -- a u ) 
  DUP 0= IF  0 EXIT THEN 
  DUP CELL+ SWAP @
;
[THEN]

REQUIRE CREATE-CS       ~pinka/lib/multi/Critical.f 
\ все, теперь без портирования синхронизации под линукс не пойдет


Require ULT             aliases.f \ набор синонимов

\ лексикон кодогенератора, управляющий стек, управление списками слов:
REQUIRE CODEGEN-WL      ~pinka/spf/compiler/index.f



\ привязка к libxml2 и XMLDOM -- в отдельный словарь XMLDOM-WL

CODEGEN-WL ALSO!

[UNDEFINED] getAttributeNS [IF]
`XMLDOM-WL WORDLIST-NAMED PUSH-DEVELOP

`~pinka/lib/lin/xml/libxml2-dom.f        INCLUDED

DROP-DEVELOP
[ELSE]
 `getAttributeNS FORTH-WORDLIST SEARCH-WORDLIST  [IF]
  FORTH-WORDLIST CONSTANT XMLDOM-WL              [ELSE]
 .( Wid of libxml2-dom.f is not found ) CR ABORT [THEN]
[THEN]

PREVIOUS



\ -----
\ Внутренности реализации в список forthml-hidden

CODEGEN-WL ALSO!  XMLDOM-WL  ALSO!
`forthml-hidden WORDLIST-NAMED PUSH-DEVELOP

VARIABLE cnode-a \ текущий узел XML-документа

Include cdomnode.immutable.f  \ DOM-доступ к текущему узлу, обход XML-дерева

DROP-DEVELOP PREVIOUS PREVIOUS


?C-JMP TRUE TO ?C-JMP  \ включение хвостовой оптимизации: [CALL XXX][RET] --> [JMP XXX]
                       \ актуально для цепочки обработчиков.
( prev-flag )




GET-CURRENT GET-ORDER ( ..prev-context.. )

FORTH-WORDLIST XMLDOM-WL CODEGEN-WL forthml-hidden  4 SET-ORDER  DEFINITIONS

: T-WORD-TC ( i*x addr u -- j*x )
  CODEGEN-WL     FIND-WORDLIST IF EXECUTE EXIT THEN
  FORTH-WORDLIST FIND-WORDLIST IF EXECUTE EXIT THEN
  NOTFOUND
;
: (INCLUDED-PLAIN-TC) ( i*x -- j*x )
  BEGIN PARSE-NAME DUP WHILE T-WORD-TC REPEAT 2DROP
;
: EVALUATE-PLAIN-TC ( a u -- )
  ['] (INCLUDED-PLAIN-TC) EVALUATE-WITH
  \ - relative to the current file
;
: INCLUDED-PLAIN-TC ( a u -- )
  FIND-FULLNAME2 \ - relative to the current file
  ['] EVALUATE-PLAIN-TC FOR-FILENAME-CONTENT
;

`ttext-index.auto.f INCLUDED-PLAIN-TC \ в виде простейшего форт-текста
\ предоставляет T-PLAIN -- слово для трансляции текста,
\ ядро для трансляции xml-дерева, переменные состояния M и STATE


..: AT-PROCESS-STARTING init-document-context ;.. \ для  model/trans/document-context2.f.xml
                        init-document-context \ входит в работу и здесь же


VARIABLE _T-PAT  ' T-SLIT _T-PAT !
: T-PAT _T-PAT @ EXECUTE ; \ используется при <get-name/>

`~pinka/fml/forthml-core.auto.f Included \ базовый набор слов (правил) ForthML


\ ---

`diagnose-error.f Included \ redefine EMBODY to save error location (spf4 specific)


: _EMBODY FIND-FULLNAME2 EMBODY ; \ учитывает и путь текуще-подключаемого файла

\ лексикон ForthML первого уровня:
`~pinka/fml/src/rules-common.f.xml _EMBODY
`~pinka/fml/src/rules-forth.f.xml  _EMBODY

\ Остальное можно загрузить проще:
`index.L2.f.xml _EMBODY
`index.L3.f.xml _EMBODY




FORTH-WORDLIST PUSH-CURRENT  0 PUSH-WARNING

`EMBODY             2DUP aka

DROP-WARNING  DROP-CURRENT


SET-ORDER SET-CURRENT
TO ?C-JMP  \ оставлять включенным нельзя, т.к. дает глюки для r-чувствительных слов.


REQUIRE enqueueNOTFOUND  ~pinka/spf/notfound-ext.f

: AsQWord ( a-text u-text -- i*x true | a u false )  \ T-QWord
  forthml-hidden::I-QUOTED-FORM IF T-LIT TRUE EXIT THEN FALSE
  \ Prefer fml implementation over ~pinka/spf/quoted-word.f
  \ It supports the form: 'wlA::wlB::specificword
;
' AsQWord preemptNOTFOUND

: AsForthmlSourceFile ( a u -- a u false | i*x true )
  2DUP S" .f.xml" ENDS-WITH 0= IF FALSE EXIT THEN
  2DUP + 0 SWAP C!
  2DUP FILE-EXISTS 0= IF FALSE EXIT THEN
  EMBODY TRUE
;
' AsForthmlSourceFile preemptNOTFOUND

REQUIRE --workdir  ~pinka/lib/options-stdio.f

\ Итого, объектного кода:
\   библиотеки, расширения и выравнивания -- 36 Кб
\   транслятор ForthML с навесками -- 47 Кб
