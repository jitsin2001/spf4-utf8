\ 05-06-2004 ~mOleg
\ Copyright [C] 2006-2007 mOleg mininoleg@yahoo.com
\ ���������, �����, �������

 REQUIRE ?DEFINED devel\~moleg\lib\util\ifdef.f

\ ----------------------------------------------------------------------------

\ �������� �� ������ ���� ��� �����
: ?BIT  ( N --> mask ) 1  SWAP LSHIFT ;

\ �������� �� ������ ���� ��� ��������� �����
: N?BIT ( N --> mask ) ?BIT INVERT ;

16 CONSTANT #VOCS

\ ----------------------------------------------------------------------------

\ ���������� ��� �������� � �������-������ HIDDEN
MODULE: HIDDEN

   HERE RET, HERE SWAP - CONSTANT ret#

   \ ������ ����������� EXIT �� �����������
   : remove-ret 0 ret# - ALLOT ;

   \ ���������� ������ ���������� STATE
   0 VALUE prev-state

   \ ����������� � ����� ����� ������� �����
   \ ���� � ������ ����������, �� ����� ������ ����������� �� �����
   \ � ������ ���������� ����������� � ����������� � ���� 32-��� ��������.
   : (verb) ( mask --> ? )
            prev-state DUP STATE !
            IF ] LIT,
               0 TO prev-state
             ELSE
            THEN PREVIOUS ;

\ ----------------------------------------------------------------------------
   \ ������������� ����� ��� �������� ����� �����
   CREATE RealName 255 ALLOT

   \ ��������� ��� ����� �� ��������� ���������
   : save ( Asc # --> ) RealName SWAP 2DUP + 0! CMOVE ;

   \ ������������ � F; � ���������� ��������� �����, ���������� �� F:
   : Using STATE @ IF COMPILE, ELSE EXECUTE THEN PREVIOUS ;

   \ ��������� ���, ������� ���������� �����������
   : (F:) ( ASC # --> ) save :NONAME ;

\ ----------------------------------------------------------------------------

   \ ������� ���� ��� ���������� �������� �������
   CREATE (CURR)  #VOCS ALLOT              (CURR) 0!

   \ ������� ��������� ������� �������, ������ ��������� �� ����� (CURR)
   : this ( wid --> )
          GET-CURRENT
          (CURR) DUP 1+!
                 DUP @ CELLS + !
          SET-CURRENT ;

   \ ������� ������� ��������, ������� � ������� (CURR), �� ���� ����������
   \ ������� ������� �� �����. ���� (CURR) �� ����������������, �������
   \ �������� ������ �������. ������ ����� ��� ����� FORTH.
   : last ( --> )
          (CURR) DUP @ CELLS + @
                     SET-CURRENT
          (CURR) 1 OVER @ 1- MAX SWAP ! ;

\ ----------------------------------------------------------------------------

   \ ��� ���������� ���������� ����������� ����� ��� ���������
   VARIABLE chain   chain 0!

   \ ����������, ������ �� �������
   : ?chain ( --> flag ) chain DUP @ SWAP 0! ;

   \ �������� wid ���������� ������������� �������
   : last-voc  ( --> wid ) VOC-LIST @ CELL+ ;

   \ ������� ��������� ������� �����������
   : with      ( wid --> ) ALSO CONTEXT ! ;

   \ ������� ��������� ������������ ������� �������
   : enter     ( -- ) last-voc DUP with this ;

   \ ����� � ���������� ������� �������
   : leave     ( -- ) PREVIOUS last ;

   \ ������� �������, ����� � ����, ������� �������
   : container ( --> ) VOCABULARY enter ;

   \ ���������� ������ ��������� � ������ ����, ��� ��� ����� ����� ����
   \ ��� ���������� � �������������� ���������
   : ?Size ( disp disp --> size ) 2DUP MAX -ROT MIN - ;

\ ----------------------------------------------------------------------------

  \ ������ ��� ���� � ������� ������� �������
  ALSO FORTH DEFINITIONS

   \ ������� �����, ����������� �����������.
   \ ����� �� ������ ������ � ���������� �����������, ��
   \ ������� ����� ��������� ����� � ������ name.
   : F: ( | name --> ) NextWord (F:) ;

   \ ��������� �����������, ������� �� F:
   \ ������� ��������� ������ � ������ name, ��������� ����� F:
   \ ��������� ���������� � ������ �� ��������� �������� �
   \ �������������� ������� �� ��������� ��������.
   : ;F ( addr --> )
        [COMPILE] ;
        RealName ASCIIZ> SHEADER IMMEDIATE
        LIT, POSTPONE Using RET, ; IMMEDIATE

   \ �������� � ���������� ����������� ����� ��� ���������
   \ ���� �� ������������ ��� �����, �� �������� ����������� �������� �
   \  �������������� ����������� ����������� PREVIOUS
   : Sub ( --> ) -1 chain ! ;

   \ ������� ������� � ������ name, ������� ��� ����������� � �������
   : Unit: ( | name --> )
           container ?chain ,
           IMMEDIATE
           DOES> DUP CELL+ @ IF ELSE ALSO THEN
                     @ CONTEXT ! ;

   \ ����� �� �������� �����, ������������ ��������� CONTEXT, CURRENT
   : EndUnit ( --> ) leave ;

\ ----------------------------------------------------------------------------

   \ ������� ��������� ���������
   : Struct: ( disp | name --> disp disp )
             DUP
             container ?chain , \ �����������
             IMMEDIATE
             DOES> DUP CELL+ @ IF ELSE ALSO THEN
                   @ CONTEXT ! ;

   \ �������� ���������
   : const  ( n --> ) F: SWAP LIT, [COMPILE] ;F ;

   \ ���������� �� ������ �������� ������������ ������ ������,
   \ �� � ������ ���� ������
   : field  ( disp # --> base )
            2DUP + >R
            ( disp --> base # )
            F: -ROT SWAP LIT, POSTPONE + LIT, [COMPILE] ;F
            R> ;

   \ ��� ����������� ���� ������������ ������
   : record ( disp # --> end )
            OVER +
            SWAP F: SWAP LIT, POSTPONE + [COMPILE] ;F ;

   \ ��� ����������� ����� ������������� �����
   : Zero[] 0 record ;  \ ��� ����������� union-�� ��� ����� �����
   : Byte[] 1 record ;
   : Word[] 2 record ;
   : Cell[] CELL record ;

   \ ��������������� ����� �� ����� ��� ������������� ��������
   \ !!! ��������, �� ���������� ���� ����������� �� ����� ������
   : noname\ ( disp # --> end ) + [COMPILE] \ ;

   \ �������� �������� ���������, ������� ��� \size, ������������
   \ ������ ���������
   : EndStruct ( displ dispu --> )
               \ ������� ��� /size, �������� ������ ���������
               ?Size S" /size" (F:) SWAP LIT, [COMPILE] ;F
               leave ;

\ ----------------------------------------------------------------------------

   \ ������ � �������� ������.
   : Funct: ( OR_mask | Name --> OR_mask )
            >R container ?chain , R@ , IMMEDIATE R>

            DOES> DUP CELL+ @ IF ELSE ALSO THEN
                  DUP @ CONTEXT !
                  8 + @

                  STATE @ IF TRUE TO prev-state [COMPILE] [ THEN  ;

   \ �������� ������� �����
   :  Mask ( m m --> m ) :        LIT, POSTPONE OR  [COMPILE] ;  ;
   : -Mask ( m m --> m ) : INVERT LIT, POSTPONE AND [COMPILE] ;  ;
   : Bit   ( m n --> m ) : ?BIT   LIT, POSTPONE OR  [COMPILE] ;  ;
   : -Bit  ( m n --> m ) : N?BIT  LIT, POSTPONE AND [COMPILE] ;  ;
   \ ������������
   : Enum  ( shift mask --> )
           : LIT, POSTPONE AND
             LIT, POSTPONE LSHIFT
             POSTPONE OR
           [COMPILE] ;  ;

   \ ��� ����� ��������� �� ��, ��� ���������� ����� ��� ����� ���������
   \ ������ �����. ��. ������ � �����. ����� ������������ � ����� ������������
   \ ��������� ����� : -- ;

   : Verb: ( --> ) remove-ret POSTPONE (verb) RET, ;


   \ ��������� �������� ������� �����.
   : EndFunct ( OR_mask --> )
              DROP
              leave ;

  PREVIOUS
;MODULE

?DEFINED test{ \EOF -- �������� ������ ---------------------------------------

test{ \ ���� ������ ���� �� ��������������.
  S" passed" TYPE
}test

\ ----------------------------------------------------------------------------

\EOF

\ ������ �������� ������� �����, ������ � �������� ������:
HEX
 F00 Funct: proba{
          3 Mask aaa
          4 Mask bbb
          9 -Bit ccc
          2 3 Enum ddd

         : } ; Verb:
  EndFunct

: first   proba{ aaa } . ;
: second  proba{ bbb } . ;
: thrid   proba{ aaa bbb } . ;
: fourth  proba{ ccc } . ;
: fifth   proba{ 5 ddd } . ;

\EOF

\ �������� ������

 Unit: proba                  CR    ORDER
     F: hello ." hello" ;F

     Sub Unit: check          CR    ORDER

     F: hello ." bye!" ;F
     EndUnit                  CR    ORDER
 EndUnit                      CR    ORDER

\EOF
������ ����� �� ������ ������� ����� �� ���������� �������, � ���������
� ���������� ���������� ����� ������� ��������� ������� �����������
������ �� ��������� ����� ����: [compile] unit � ���� �����������. ��������,
��� ��� �� ������ �����, ���� ����� �������. ������� ����� ���������
�����-�� �����, ����� � ��� �������� ��� ����, � ��� ��� � ���� �� ����� 8)


����, ��������� ����� ����������� ��������� ��������� ��� ������ ����������.
� ������, ��� �������� ������� ��� ����� ������ ��� ������� � �����������,
��� ��� �������� �����: ALSO vocName DEFINITIONS, � � �����: PREVIOUS
DEFINITIONS. ����� ���� ������� ���������� IMMEDIATE, �� ���� � ������
���������� ����� �� ������� ����� ������ �������.

����� ������� �� MODULE: ��������� � ���. ��-������, �� ��� ������ ����� ������
������������ ������������ ��������� �������:

        Unit: Azimuth
          Sub Unit: Go
              F: Left  ... ;F
              F: Right ... ;F
          EndUnit
        EndUnit

� �����:

        Azimuth Go Left
        Altitude Go Up
������ ��� ������ �������� ������ ����� ���������, � ��
        Azimuth::Go::Left
��� ��� � ���� ����� ��������� ��������������, ��� ���� �����.
�� � ������� ���������, ��� ��� ������� �������� ����� �� �������,
��� ����� �� ������� notfound.

---
������ � �������� ������ �������� ����� ��� ��, ��� � �� �����������,
�� ����� ��������� ������� ��������� � ���, ��� � ����� ���� �����
������������ ��������������� � ������������ ��������� ���. ��-�� ����
����������� ����� ���������� ����� �������� ���� (�������, ��� ���
�������) �� ���� ������������� ����� ����� ���� (�� ��������) � �������������
��������� � ����� ����������, �� ��� ���, ���� �� �������� �����, ����������
��������� Verb:, ������� �� ���� �������� �� ������� ���������, �������
�������� �������� ������ ����� �������� ��������� � ���� �����������.
���� ��������� ����� �������� ������� �����:
     - n Bit ���������� ��������� ��� � �����
     - n -Bit �������� ��������� ��� � �����
     - x Mask ���������� ��������� ����
     - x -Mask �������� ��������� ����    (����� �������� � ������ ����)
     - s m Enum ��� ������������� ��������������, ���������� �� Enum
       ���������� �� ����� ����� ����� �������� �� m ����� � �������� s
       ��� �����, ��������� ������ ����� �� OR ������ � ������� ������.
��� �������� �������� ��� ������ � �������. ����� ������ ��� �������������
����� ��������. �� ���� ���������� ������ ����������, ����� �����������
������� ������� �������� ����������(� ��������� ������������� ������).

