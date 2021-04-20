; Simple minimal Extern CODE that changes value of flag 100
; To be assembled with A86 assembler software
EXTERN:

    PUSH BP
    MOV BP,SP ; Cabecera

    MOV [BX+100], AL ; Set Flag 100 to value of EXTERN parameter 1 (AL)

    MOV SP,BP ; Salida
    POP BP
    RETF



