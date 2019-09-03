

REQUIRE BEGIN-CODE  ~day\common\code.f 

(  В Pentium'е разработчиками была введена команда RDTSC, возвращающая число
тактов процесора с момента подачи на него напряжения. Код этой команды $0F $31.
команда возвращает восьмибайтное число в регистрах EDX:EAX. 
)

BEGIN-CODE
ALSO ASSEMBLER

CODE GetTicks  (  -- tlo thi )
     RDTSC
     SUB EBP, # 8
     MOV [EBP], EDX
     MOV 4 [EBP], EAX
     RET
END-CODE

PREVIOUS
CLOSE-CODE

BYE
