
{$I SETTINGS.INC}

{$G+} 
(*   Overrides general setting, so using VESA modes requires a 286, or actually a 386 *)
(*   because will be using 386 instrucctions using DB prefixes.                       *)
(*   Note: there is a $G- at the end of this unit.                                    *)
unit vesa;


interface

const WindowA=0;
      WindowB=1;

type
VGAInfoBlock = record
                VESASignature:array[1..4] OF Char;
                VESAVersion:word;
                OEMStringPtr:Pointer;
                Capabilities:array[1..4] OF byte;
                VideoModePtr:Pointer;
                TotalMemory:word;
                Reserved:array[0..235] OF Byte;
               end;

ModeInfoBlock = RECORD
                 ModeAttributes:word;
                 WinAAttributes:Byte;
                 WinBAttributes:Byte;
                 WinGranularity:word;
                 WinSize:word;
                 WinASegment:word;
                 WinBSegment:word;
                 WinFuncPtr:word;
                 BytesPerScanLine:word;

                 XResolution:word;
                 YResolution:word;
                 XCharSize:Byte;
                 YCharSize:Byte;
                 NumberOfPlanes:Byte;
                 BitsPerPixel:Byte;
                 NumberOfBanks:Byte;
                 MemoryModel:Byte;
                 BankSize:Byte;
                 NumberOfImagePages:Byte;
                 BytesPerScanLine2:Byte;
                 Reserved:Byte;

                 RedmaskSize:Byte;
                 RedFieldPosition:Byte;
                 GreenMaskSize:Byte;
                 GreenFieldPosition:Byte;
                 BlueMaskSize:Byte;
                 BlueFieldPosition:Byte;
                 RsvdMaskSize:Byte;
                 DirectcolorModeInfo:Byte;
                 Reserved2:array[0..215] OF byte;
                end;

var VESAEnabled:Boolean;
    VESAINFO:VGAInfoBlock;
    Granularity:Longint;
    ByteGranularity:Longint;
    VESAScreenWidth:word;
    VESAscreenHeight:word;
    ActiveBank:word;


function VESAGetInfo(var Info:VGAInfoBlock):word;
function VESAValidMode(Mode:word):Boolean;
function VESAVideoRAMSize:word;
function VESAGetModeInfo(mode:word; var IB:ModeInfoBlock):word;
function VESASetMode(Mode:word;defaultWidth:word):word;
function VESAGetMode(var Mode:word):word;
function VESASetWindow(Bank:word;Window:Byte):word;
function VESAGetWindow(var Bank:word;Window:Byte):word;
function VESASetDisplayStart(Line:word;Pixel:word):word;
function VESAGetMaxLine:word;
procedure VESAPutImage(X,Y:longint;width, height:word; var Buffer; OffJmp:word);
procedure VESAGetImage(X,Y:longint;width, height:Word;VAR Buffer);
procedure VESARectangle(X,Y:longint;width, height:word;color:Byte);
procedure VESAPutPixel(X,Y:longint;color:Byte);


implementation

type widthType=array[Byte] OF Byte;


function GetGranularity:word;
var IB:ModeInfoBlock;
    Mode:word;
begin
    VESAGetMode(Mode);
    VESAGetModeInfo(Mode,IB);
    GetGranularity:=IB.WinGranularity;
end;

function VESAGetInfo(var Info:VGAInfoBlock):word; Assembler;
ASM
    MOV AX,4F00h
    LES DI,[Info]
    INT 10h
end;


function VESAVideoRAMSize:word;
begin
    VESAVideoRAMSize:=VESAInfo.TotalMemory*64;
end;

function VESAValidMode(Mode:word):Boolean;
var ModeList:^word;
begin
    ModeList := VESAInfo.VideoModePtr;
    VESAValidMode:=False;
    while ModeList^<>$0FFFF do begin
                                IF ModeList^ = Mode THEN VESAValidMode:=True;
                                Inc(longint(ModeList),2);
                            end;
end;


function VESAGetModeInfo(mode:word; var IB:ModeInfoBlock):word; Assembler;
ASM
    MOV AX,4F01h
    MOV CX,Mode
    LES DI,[IB]
    INT 10h
end;

function VESASetMode(Mode:word; defaultWidth:word):word;
begin
    asm
        MOV AX,4F02h
        MOV BX,Mode
        INT 10h
    end;
    VESAScreenWidth := defaultWidth;
    Granularity := GetGranularity;
    ByteGranularity := Granularity*1024;
    CASE Mode OF
        $100:VESAscreenHeight:=400;
        $101:VESAscreenHeight:=480;
        $103:VESAscreenHeight:=600;
        $105:VESAscreenHeight:=768;
    end;
end;



function VESAGetMode(var Mode:word):word; Assembler;
asm
    MOV AX,4F03h
    INT 10h
    LES DI,[MODE]
    MOV ES:[DI],BX
end;

function VESASetWindow(Bank:word;Window:Byte):word; Assembler;
asm
    MOV DX,Activebank
    MOV CX,Bank
    CMP CX,DX
    JZ @FIN
    MOV ActiveBank,CX
    MOV AX,4F05h
    XOR BH,BH
    MOV BL,Window
    MOV DX,Bank
    INT 10h
    @FIN:
end;

function VESAGetWindow(var Bank:word;Window:Byte):word; Assembler;
ASM
    MOV AX,4F05h
    MOV BH,1
    MOV BL,Window
    INT 10h
    LES DI,[Bank]
    MOV ES:[DI],DX
end;

function GetLineWidth(var length:word):word; Assembler;
ASM
    MOV AX,4F06h
    MOV BL,1
    INT 10h
    LES DI,[length]
    MOV ES:[DI],CX
end;

function VESASetDisplayStart(Line:word;Pixel:word):word; Assembler;
ASM
    XOR BX,BX
    MOV AX,4F07h
    MOV CX,Pixel
    MOV DX,Line
    INT 10h
end;


function VESAGetMaxLine:word; Assembler;
ASM
    MOV AX,4F06h
    MOV BL,1
    INT 10h
    MOV AX,DX
end;

procedure VESAPutPixel(X,Y:longint;color:Byte);
var Offset:longint;
    Desp:word;
begin
 Offset:=x+y*VESAScreenWidth;
 Desp:=Offset MOD ByteGranularity;
 VESASetWindow(Offset DIV ByteGranularity,WindowA);
 Mem[$a000:Desp]:=color;
end;



procedure VESARectangle(X,Y:longint;width, height:word;color:Byte);
var Offset:Longint;
    Desp:word;
    Bank:word;
    l_w:word;
    Step:word;
begin
    Step:=64 DIV Granularity;
    Offset:=Y*VESAScreenWidth+X;
    bank:=Offset DIV (ByteGranularity);
    desp:=Offset MOD (ByteGranularity);
    VESASetWindow(bank,WindowA);
    l_w:=VESAScreenWidth;
    asm
    CLD

    MOV AX,0A000h
    MOV ES,AX
    MOV DI,Desp

    MOV AL, color
    MOV AH, AL
    MOV BX, AX
    { SHL EAX, 16 }         DB 066h, 0C1h, 0E0h, 10h
    MOV AX, BX

    MOV CX,height
    @Bucle:
    PUSH CX
    MOV CX,width

    @BUC:
    MOV BX, DI
    ADD BX, CX
    JC  @SheightBANCO

    MOV DX, CX
    SHR CX, 2
    JZ @NOSD
    { REP STOSD }         DB 66h ; REP STOSW
    AND DX, 3
    JZ @FINFILA
    @NOSD:
    MOV CX, DX
    REP STOSB
    JMP @FINFILA

    @SheightBANCO:

    MOV DX, DI
    NOT DX
    INC DX
    XCHG DX, CX
    SUB DX, CX
    REP STOSB

    PUSH DX
    PUSH AX
    MOV CX,Bank
    add cx,Step
    mov Bank,cx
    MOV AX,4F05h
    SUB BX,BX
    MOV DX,CX
    INT 10h
    POP AX
    POP CX
    JCXZ @FINFILA
    REP STOSB

    @FINFILA:

    MOV CX, l_w
    SUB CX, width
    ADD DI, CX
    JNC @no_c_banco

    @c_banco:
    MOV CX,Bank
    add cx,step
    mov bank,cx
    PUSH AX
    MOV AX,4F05h
    SUB BX,BX
    MOV DX,CX
    INT 10h
    POP AX

    @no_c_banco:
    pop cx
    dec cx
    jnz @bucle
    end;
    ActiveBank := Bank ;
end;

procedure VESAPutImage(X,Y:longint; width, height:word; var Buffer; OffJmp:word);
var Offset:Longint;
    Desp:word;
    Bank:word;
    l_w:word;
    Step:word;
begin
 Step:=64 DIV Granularity;
 Offset:=Y*VESAScreenWidth+X;
 bank:=Offset DIV (ByteGranularity);
 desp:=Offset MOD (ByteGranularity);
 VESASetWindow(bank,WindowA);
 l_w:=VESAScreenWidth;
 ASM
  CLD
  PUSH DS

  MOV AX,0A000h
  LDS SI,Buffer
  MOV ES,AX
  MOV DI,Desp

  MOV CX,height
  @Bucle:
   PUSH CX
   MOV CX,width

   @BUC:
    MOV BX, DI
    ADD BX, CX
    JC  @SheightBANCO

    MOV DX, CX
    SHR CX, 2
    JZ @NOSD
  { REP MOVSD }         DB 66h ; REP MOVSW
    AND DX, 3
    JZ @FINFILA
   @NOSD:
    MOV CX, DX
    REP MOVSB
    JMP @FINFILA

   @SheightBANCO:

    MOV DX, DI
    NOT DX
    INC DX
    XCHG DX, CX
    SUB DX, CX
    REP MOVSB

    PUSH DX
    PUSH AX
    MOV CX, Bank
    ADD CX, Step
    MOV Bank, CX
    MOV AX, 4F05h
    SUB BX, BX
    MOV DX, CX
    INT 10h
    POP AX
    POP CX
    JCXZ @FINFILA
    REP MOVSB

   @FINFILA:

    MOV CX, l_w
    SUB CX, width
    ADD DI, CX
    JNC @no_c_banco

   @c_banco:
    MOV CX, Bank
    ADD CX, Step
    MOV Bank, CX
    PUSH AX
    MOV AX,4F05h
    SUB BX,BX
    MOV DX,CX
    INT 10h
    POP AX

   @no_c_banco:
   ADD SI, OffJmp
   POP CX
   DEC CX
   JNZ @Bucle

   POP DS
  end;
 ActiveBank := Bank ;
end;


procedure VESAGetImage(X,Y:longint;width, height:Word;VAR Buffer);
VAR Offset:Longint;
    Desp:Word;
    Bank:WorD;
    l_w:word;
    Step:Word;
begin
 Step:=64 DIV Granularity;
 Offset:=Y * VESAScreenWidth + X;
 bank := Offset DIV (ByteGranularity);
 desp := Offset MOD (ByteGranularity);
 VESASetWindow(bank,WindowA);
 l_w := VESAScreenWidth;
 ASM
  CLD
  PUSH DS

  MOV AX,0A000h
  LES DI,Buffer
  MOV DS,AX
  MOV SI,Desp

  MOV CX,height
  @Bucle:
   PUSH CX
   MOV CX,width


   @BUC:
    MOV BX, SI
    ADD BX, CX
    JC  @SheightBANCO

    MOV DX, CX
    SHR CX, 2
    JZ @NOSD
  { REP MOVSD }         DB 66h ; REP MOVSW
    AND DX, 3
    JZ @FINFILA
   @NOSD:
    MOV CX, DX
    REP MOVSB
    JMP @FINFILA

   @SheightBANCO:

    MOV DX, SI
    NOT DX
    INC DX
    XCHG DX, CX
    SUB DX, CX
    REP MOVSB

    PUSH DX
    PUSH AX
    MOV CX, Bank
    ADD CX, Step
    MOV Bank, CX
    MOV AX, 4F05h
    SUB BX, BX
    MOV DX, CX
    INT 10h
    POP AX
    POP CX
    JCXZ @FINFILA
    REP MOVSB

   @FINFILA:

    MOV CX, l_w
    SUB CX, width
    ADD SI, CX
    JNC @no_c_banco

   @c_banco:
    MOV CX, Bank
    ADD CX, Step
    MOV Bank, CX
    PUSH AX
    MOV AX,4F05h
    SUB BX,BX
    MOV DX,CX
    INT 10h
    POP AX

   @no_c_banco:
   POP CX
   DEC CX
   JNZ @Bucle

   POP DS
  end;
 ActiveBank := Bank ;
end;


begin
 VESAEnabled:=VESAGetInfo(VesaInfo)=$004F;
END.
{$G-}