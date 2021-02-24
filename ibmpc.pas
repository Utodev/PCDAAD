unit ibmpc;
(* IBM PC specific functions *)

interface

function GetKey:Word; 

implementation



function GetKey : Word; Assembler;
(* Returns keyboard code:

            if  <256    ->  estandar  ASCII code
                >=256   -> Extended ASCII code -> Hi(GetKey)= Code
                =0      -> no key pressed *)
asm
    MOV AH,1
    INT $16
    MOV AX,0
    JNZ @getKeyEnd
    INT $16
    OR AL,AL
    JZ @getKeyEnd
    SUB AH,AH
    @getKeyEnd:
end;


END.
