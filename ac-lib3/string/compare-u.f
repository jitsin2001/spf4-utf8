: COMPARE-U ( addr1 u1 addr2 u2 -- flag )
  SWAP >R >R
  R@ <> IF DROP 2R> 2DROP TRUE EXIT THEN
  R> R> SWAP 0
  ?DO 2DUP I + C@ SWAP I + C@ - ABS DUP 0= SWAP 32 = OR
      0= IF 2DROP UNLOOP TRUE EXIT THEN
  LOOP 2DROP FALSE
;
