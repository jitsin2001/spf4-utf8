( ����������������� ��������� ����������.
  Copyright [C] 1992-1999 A.Cherezov ac@forth.org
  �������������� �� 16-���������� � 32-��������� ��� - 1995-96��
  ������� - �������� 1999
)

USER HANDLER      \ ����������� ����������

' NOOP ->VECT FATAL-HANDLER
\ ���� � ���������� ����� ����������� �������� �������� HANDLER,
\ ������������� ��� ����� � �����/������ ��� �������,
\ �� ���������� ���� ���������� FATAL-HANDLER

: THROW ( k*x n -- k*x | i*x n ) \ 94 EXCEPTION
\ ���� ����� ���� n ���������, ����� ������� ���� ���������� �� �����
\ ����������, ������� ��� �� ����� ��������� ��� ���� ������. �����
\ ������������ ������������ �������� ������, ������� ������������� �����
\ ��������������� CATCH, � ���������� ������� ���� ������, ������������
\ � ���� ���������, � �� ���������, ������� ���� ��������� � �����
\ ���������� (i - ��� �� �� �����, ��� � i �� ������� ����������
\ ���������������� CATCH), �������� n �� ������� ����� ������ � ��������
\ ���������� � ����� ����� ����� CATCH, ������� �������� ���� ����
\ ����������.
\ ���� ������� ����� �� ����, � �� ����� ���������� ���� ���� 
\ ����������, �� ��������� ���������:
\   ���� n=-1, ��������� ������� ABORT (������ ABORT �� ���� CORE), 
\   �� ������ ���������.
\   ���� n=-2, ��������� ������� ABORT" (������ ABORT" �� ���� CORE), 
\   ������ ������� ccc, ��������������� � ABORT", ������������ THROW.
\   ����� ������� ����� ������� �� ������� ��������� �� ���������� 
\   ��������� �� �������, ��������������� THROW � ����� n. ����� 
\   ������� �������� ������� ABORT (������ ABORT �� CORE).
  DUP 109 = IF DROP EXIT THEN \ broken pipe - ������ �� ������, � ����� �������� ������ � CGI
  
  ?DUP
  IF HANDLER @ 
     ?DUP
     IF RP!
        R> HANDLER !
        R> SWAP >R
        SP! DROP R>
     ELSE FATAL-HANDLER THEN
  THEN
;

' THROW (TO) THROW-CODE

VECT <SET-EXC-HANDLER> \ ���������� ���������� ���������� ����������

: CATCH ( i*x xt -- j*x 0 | i*x n ) \ 94 EXCEPTION
\ �������� �� ���� ���������� ���� ��������� �������������� ��������
\ � ��������� ����� xt (��� �� EXECUTE) ����� �������, ����� ����������
\ ����� ���� �������� � ����� ����� ����� CATCH, ���� �� ����� ����������
\ xt ����������� THROW.
\ ���� ���������� xt ������������� ��������� (�.�. ���� ����������,
\ ���������� �� ���� ������ CATCH �� ��� ���� ����������� THROW),
\ ����� ���� ���������� � ������� ���� �� ������� ����� ������,
\ ��������� �������� ����� ������������ xt EXECUTE. ����� �������
\ ��������� ���������� ������ THROW.
  SP@ >R  HANDLER @ >R
  RP@ HANDLER !
  EXECUTE
  R> HANDLER !
  RDROP
  0
;
: ABORT  \ 94 EXCEPTION EXT
\ ��������� �������� CORE ABORT ����� ����:
  ( i*x -- ) ( R: j*x -- )
\ ��������� ������� -1 THROW
  -1 THROW
;
