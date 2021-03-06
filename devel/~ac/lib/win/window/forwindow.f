\ $Id$
\ ForWindowNamed ( addr u x -- ) выполняет заданное действие x для
\ окон, содержащих в заголовке строку addr u.
\ Исходное назначение - управлять окнами других программ из ~yz/xmenu

REQUIRE WindowHide    ~ac/lib/win/window/window.f 
REQUIRE ForEachWindow ~ac/lib/win/window/enumwindows.f 

VARIABLE twNameu 
VARIABLE twNamea
VARIABLE twNamex

: WindowActiveShow
  DUP WindowShow
  DUP WindowRestore DUP WindowToTop WindowToForeground 
;
: ToggleWindowN
  DUP IsWindowVisible 
  IF DUP WindowMinimize WindowHide 
  ELSE WindowActiveShow
  THEN
;
: (ForWindowNamed)
  DUP 512 PAD ROT GetWindowTextA PAD SWAP ?DUP 
  IF twNamea @ twNameu @ SEARCH NIP NIP
     IF twNamex @ EXECUTE THEN
  ELSE 2DROP THEN
  TRUE
;
: ForWindowNamed ( addr u x -- )
  twNamex ! twNameu ! twNamea !
  ['] (ForWindowNamed) ForEachWindow DROP
;
: ToggleWindowNamed
  ['] ToggleWindowN ForWindowNamed
;
\ : TEST
\   S" eChat 0.1" ToggleWindowNamed
\ ;
