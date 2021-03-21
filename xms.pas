{$I SETTINGS.INC}
unit XMS;

{$I-,S-R-,X+}

interface

tyle XMSHandle=Word;

var XMSAvailable:Boolean; (* True if there is XMS available *)

procedure GetXMSVersionNumber(var version,internal:Word;var HMAexist:Boolean); 
(* Returns BCD value and if HMA is available*)

function XMSMemAvail:Word; 
(* Returns number of KB of XMS RAM available *)

function MaxXMSMemAvail:Word; 
(* Returns number of KB of maxi XMS block available *)

function GetXMSMem(var Handle:XMShandle; Size:Word):Byte;
(* Tries to reserve a XMS block of the Size (in Kb)           *)
(* On success the handle is returned and function returns 1    *)
(* On failure the handle is set to 0 and the function returns: *)
(* $80 if function not implemented                             *)
(* $81 if no VDISK device found                                *)
(* $A0 if no more XMS RAM available, or no blocks of that size *)
(* $A1 if no more XML handles available                        *)

function FreeXMSMem(var Handle:XMShandle):Byte;
(*  Tries to free the XML block indentified by the handel     *)
(* On success returns 1                                       *)
(* On failure returns                                         *)
(* $80 if function not implemented                            *)
(* $81 if no VDISK device found                               *)
(* $A2 if handle is not valid                                 *)
(* $AB if handle is locked                                    *)
(* Note: you must free all XMS blocks before exiting program  *)
(* or the memory will remain used after quitting to DOS       *)

function XMSMove( SRCHandle:Word;SRCOffset:LongInt;
                  DSTHandle:Word;DSTOffset:Longint;length:Longint):Byte;
(* Moves a block from XMS to XMS, from XMS to base RAM, or from base RAM to XMS *)                  
(* If the handle provided is 0, then the offset is an offset in base RAM        *)
(* It's highly recommend that the length is a multiple of 4                     *)
(* Returns 1 on success                                                         *)
(* On failure returns                                                           *)
(* $80 if function not implemented                                              *)
(* $81 if no VDISK device found                                                 *)
(* $82 if an error in the A20 line happened                                     *)
(* $A3 if source handle is not valid                                            *)
(* $A4 if source offset is not valid                                            *)
(* $A5 if target handle is not valid                                            *)
(* $A6 if target offset is nor valid                                            *)
(* $A7 if lenght is not valid                                                   *)
(* $A8 if movement would make an invalid overlap                                *)
(* $A9 parity error                                                             *)
(*                                                                              *)
(*  If movement overlap, it will be calid only if it's made forward             *)
(*  If both handles are 0, there will be a movement from base RAM to base RAM,  *)
(*  but much slower than usual, so it's not recommended                         *)

{ Samples XMSMOVE:

   var XMS1,XMS2:XMSHandle;
       P:Pointer;
       A:ARRAY[0..7] OF Byte;

   begin
    GetXMSMem(XMS1,8); (* Obtain 8K of XMS memory*)
    GetXMSMem(XMS2,16); (* 16K in XMS2 *)
    getMem(P,8192);  (* 8K in base memory *)


    (* Copy from XMS to XMS *)
    XMSMove(XMS1,0,XMS2,0,8192); (* Copies first 8Ks at XMS1 in first 8Ks at XMS2 *)
    XMSMove(XMS2,8192,XMS1,0,8192); (* Copies second 8Ks at XMS2 in XMS1 *)
    XMSMove(XMS2,527,XMS1,1890,500); (* Copies 500 bytes from offset 527 at 
                                        XMS2 to offset 1890 at XMS1 *)

    (* From XMS to base RAM *)

    XMSMove(XMS1,0,0,longint(p),8192); (* Copy 8K at XMS1 to address pointed by pointer P *)                                         
                                          
    XMSMove(XMS2,500,0,longint(@A),8); (* Copy 8 bytes from offset 500 at XMS2 to array A *)
    XMSMove(XMS1,0,0,longint(@a)+4,4); (* Copy 4 bytes from XMS1 to A[4] *)

    (* From RAM to XMS is just like above but swapping source and destination. *)

    FreeXMS(XMS1);
    FreeXMS(XMS2);
    FreeMem(P,8192);

 }



function GetNumhandles(Q:XMSHandle):Byte;
(* Returns number of handles available *)



implementation

var XMSProc:procedure;
    MemMove:record
             Length:Longint;
             SourceHandle:Word;
             SourceOffset:LongInt;
             DestHandle:Word;
             DestOffset:LongInt
            end;

(* Please notice this function requires an active handler to determine how many more are left *)
function GetNumhandles(Q:XMSHandle):Byte; Assembler;
asm
 MOV AH,0Eh
 MOV DX,Q
 CALL DWORD PTR XMSproc
 XOR AH,AH
 MOV AL,BL
end;

function MemXMSAvail:Word; Assembler;
asm
 MOV AH,8
 CALL DWORD PTR XMSProc
 MOV AX,DX
end;

function MaxXMSAvail:Word; Assembler;
asm
 MOV AH,8
 CALL DWORD PTR XMSProc
end;



procedure GetXMSVersionNumber(var version,internal:Word;var HMAexist:Boolean);
begin
 asm
  XOR Ah,AH
  call dword ptr XMSProc
  LES DI,[version]
  STOSW
  LES DI,[internal]
  MOV AX,BX
  STOSW
  MOV AX,DX
  LES DI,[HMAExist]
  STOSB
 end;
end;

function GetXMSMem(var Handle:XMShandle;Size:Word):Byte; Assembler;
asm
 MOV AH,09h
 MOV DX,Size
 CALL DWORD PTR XMSProc
 LES DI,[Handle]
 MOV ES:[DI],DX
 CMP AX,1
 JZ @FIN
 XOR BH,BH
 MOV AX,BX
 @FIN:
end;

function FreeXMSMem(var Handle:XMShandle):Byte; Assembler;
asm
 MOV AH,0Ah
 LES SI,[handle]
 MOV DX,ES:[SI]
 CALL DWORD PTR XMSProc
 CMP AX,1
 JZ @FIN
 XOR BH,BH
 MOV AX,BX
 @FIN:
end;

function XMSMove(SRCHandle:Word;SRCOffset:LongInt;DSTHandle:Word;DSTOffset:Longint;length:Longint):Byte;
var Aux:Byte;
begin
 MemMove.SourceHandle:=SRCHandle;
 MemMove.SourceOffset:=SRCOffset;
 MemMove.length:=length;
 MemMove.DestHandle:=DSTHandle;
 MemMove.DestOffset:=DSTOffset;
 asm
  PUSH DS
  MOV SI,Offset MemMove
  MOV AX,SEG MemMove
  MOV DS,AX
  MOV AH,0Bh
  CALL DWORD PTR XMSProc
  CMP AX,1
  JZ @FIN
  XOR BH,BH
  MOV AX,BX
  @FIN:
  MOV Aux,AL
  POP DS
 end;
 XMSMove:=Aux;
end;

(* MAIN *)
begin
 XMSAvailable:=False;
 asm
  mov     ax,4300h
  int     2Fh
  cmp     al,80h
  jne     @NoXMSDriver
  mov     XMSAvailable,1
  @NoXMSDriver:
 end;
 IF XMSAvailable THEN
  asm
   mov     ax,4310h
   int     2Fh
   mov     word ptr [XMSProc],bx
   mov     word ptr [XMSProc+2],es
  end;
end.

