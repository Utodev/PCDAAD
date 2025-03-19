{$I SETTINGS.INC}
{$G+} {Requires 286}
{$F+}
{
    Mouse support for DAAD games. At the end of this unit, which is generic for mouse
    there is info about how the MOUSE condact works in DAAD, as it was discovered
    by Jose Luis Cebrián while developing ADP
}

unit mouse;



interface

const POINTER_DIMENSION = 9; {Size of pointer = 9x9}

type PointerSprite = array[0 .. POINTER_DIMENSION * POINTER_DIMENSION -1] of Byte;

var PointerActive:Boolean; {Whether the pointer is active or not}

procedure ResetMouse; {Initializes mouse driver and handler, must be called before using the others}
procedure ShowMouse; {Tuns pointer on}
procedure HideMouse; {Turns pointer off}
procedure InitializeMouse; {Initializes mouse unit, called by PCDAAD main program on startup. 
                           Reset Mouse is the one that actually initializes the mouse driver}
procedure TerminateMouse; {Removes handler, must be called before exiting to DOS}

{GetMouse returns the mouse position and button state.}
procedure GetMouse(var X,Y : Word; var LeftButton,CenterButton,RightButton : Boolean);  

procedure MovePointer(X,Y : Word);
{Moves the pointer to another position, the pointer must be hidden to be moved}

{Limits mouse movement to a certain range}
procedure XRange(Min,Max : Word);
{Limits mouse movement to a certain range, Y axis}
procedure YRange(Min,Max : Word);


{Change pointer to a custom one}
procedure ChangePointer(var newPointer: PointerSprite; HotspotX, HotspotY:Integer);
procedure ChangePointerFromFile(PointerFileNumber: Byte);

procedure SetOffset(X,Y:Integer); {Changes hot spot in the mouse pointer}
procedure SetOffsetX(X:Integer); {Changes hot spot X coord in the mouse pointer}
procedure SetOffsetY(Y:Integer); {Changes hot spot Y coord in the mouse pointer}


function MouseStatus(left,  middle, right: Boolean): Byte;
(* Returns the status of the mouse buttons, 1 if left button is pressed, 2 if right, 4 if middle *

(* this array represents the mouse pointe. In cas you modify POINTER_DIMENSION *)
(*  Values represent a 9x9 pointer, and the values represent the colour *)
const MousePointer : PointerSprite=
                     (15,15,00,00,00,00,00,00,00,
                         15,07,15,00,00,00,00,00,00,
                         15,07,07,15,00,00,00,00,00,
                         15,07,07,07,15,00,00,00,00,
                         15,07,07,07,07,15,00,00,00,
                         15,07,07,07,07,07,15,00,00,
                         15,07,07,15,15,15,15,00,00,
                         15,07,15,00,00,00,00,00,00,
                         15,15,00,00,00,00,00,00,00);



implementation

uses dos, flags, log, utils, ibmpc, vesa;

var Background:PointerSprite; {Saves the screen under the pointer}
    
    LastX, LastY: Word; {Saves last pointer position}
    MouseInitialized: Boolean; {Whether the mouse has been initialized or not}
    
    DeltaX, DeltaY : Integer; {Represent the pointer hot spot, where
    you click with the mouse. It's the distance from the upper left corner}

procedure SetOffset(X,Y:Integer);
begin
 if not mouseInitialized then Exit;
 DeltaX := X;
 DeltaY := Y
end;

procedure SetOffsetX(X:Integer); {Changes hot spot X coord in the mouse pointer}
begin
 if not mouseInitialized then Exit;
 DeltaX := X;
end;

procedure SetOffsetY(Y:Integer); {Changes hot spot Y coord in the mouse pointer}
begin
 if not mouseInitialized then Exit;
 DeltaY := Y;
end;


function getButtonNumber : Byte; Assembler;
asm
 XOR AX,AX
 INT 33h
 MOV AL,BL
end;

procedure InstallHandler(Handler:Pointer; Mask:Word); Assembler; {Installs the handler that moves the pointer}
asm
 LES DX,[Handler]
 MOV AX,12
 MOV CX,Mask
 INT 33h
end;


procedure SetMouseMickeyPixelRatio(horizontal, vertical: Word); Assembler;
asm
 MOV AX,0Fh
 MOV CX,horizontal
 MOV DX,vertical
 INT 33h
end;


procedure preserveBackgroundSVGA(X,Y:Word);
begin
    VESAGetImage(X,Y, POINTER_DIMENSION, POINTER_DIMENSION, BackGround);
end;

{G+}  (* Requires 286 *)
procedure preserveBackgroundVGA(X,Y:Word);Assembler;
asm
 CLD
 PUSH DS
 MOV  AX,0A000h
 MOV  DS,AX
 MOV  CX,Y
 MOV  AX,CX
 SHL  CX,8
 SHL  AX,6
 ADD  AX,CX
 ADD  AX,X
 MOV  SI,AX
 MOV  AX,SEG BackGround
 MOV  ES,AX
 MOV  DI, OFFSET BackGround
 MOV  CX,POINTER_DIMENSION
 @Loop:
  PUSH CX
  MOV  CX,POINTER_DIMENSION
  REP MOVSB
  POP  CX
  SUB  SI,POINTER_DIMENSION
  ADD  SI,320
 LOOP @Loop
 POP  DS
end;

procedure preserveBackground(X,Y:Word);
begin
 if SVGAMode then preserveBackgroundSVGA(X*4,Y*2)
             else preserveBackgroundVGA(X,Y);
end;



procedure restoreBackgroundSVGA(X,Y:Word);
begin
    VESAPutImage(X,Y, POINTER_DIMENSION, POINTER_DIMENSION, BackGround, 0);
end;

procedure restoreBackgroundVGA(X,Y:Word);Assembler;
asm
 CLD
 PUSH DS
 MOV  AX,0A000h
 MOV  ES,AX
 MOV  AX,Y
 MOV  DX,AX
 SHL AX,8
 SHL DX,6
 ADD AX,DX
 ADD  AX,X
 MOV  DI,AX
 MOV AX,SEG BackGround
 MOV DS,AX
 MOV SI, OFFSET BackGround
 MOV CX,POINTER_DIMENSION
 @Loop:
 PUSH CX
 MOV CX,POINTER_DIMENSION
 REP MOVSB
 POP CX
 SUB DI,POINTER_DIMENSION
 ADD DI,320
 LOOP @Loop
 POP DS
end;

procedure restoreBackground(X,Y:Word);
begin
 if SVGAMode then restoreBackgroundSVGA(X*4,Y*2)
             else restoreBackgroundVGA(X,Y);
end;



procedure DrawPointerSVGA(X,Y:Word); 
var XX, YY: Word;
begin
    for XX := 0 to POINTER_DIMENSION - 1 do
        for YY := 0 to POINTER_DIMENSION - 1 do
            if MousePointer[XX + YY * POINTER_DIMENSION] <> 0 then
                VESAPutPixel(X + XX, Y + YY, MousePointer[XX + YY * POINTER_DIMENSION]);
end;

procedure DrawPointerVGA(X,Y:Word); Assembler;
asm
 CLD
 PUSH DS
 MOV  AX,0A000h
 MOV  ES,AX
 MOV  AX,Y
 MOV  DX,AX
 SHL AX,8
 SHL DX,6
 ADD AX,DX
 ADD  AX,X
 MOV  DI,AX
 MOV AX,SEG MousePointer
 MOV DS,AX
 MOV SI, OFFSET MousePointer
 MOV CX,POINTER_DIMENSION
@Loop:
 PUSH CX
 MOV CX,POINTER_DIMENSION
@Loop2:
 LODSB
 OR AL,AL
 JZ @continue
 STOSB
 DEC DI
@continue:
 INC DI
 LOOP @Loop2
 POP CX
 SUB DI,POINTER_DIMENSION
 ADD DI,320
 LOOP @Loop
 POP DS
end;

procedure DrawPointer(X,Y:Word);
begin
 if SVGAMode then DrawPointerSVGA(X*4,Y*2)
             else DrawPointerVGA(X,Y);
end;


procedure InterruptHandler; {This handler will move the pointer}
VAR SX, SY:Word;
    PA : Boolean;
    LX, LY : Word;
begin
 asm
  PUSH DS
  SHR CX,1
  MOV SX,CX
  MOV SY,DX
  MOV AX,SEG PointerActive
  MOV DS,AX
  MOV SI,OFFSET PointerActive
  LODSB
  MOV PA,AL
  MOV SI,Offset LASTX
  LODSW
  MOV LX,AX
  MOV AX,SX
  MOV SI,Offset LASTX
  MOV DS:[SI],AX
  MOV SI,Offset LastY
  LODSW
  MOV LY,AX
  MOV AX,SY
  MOV SI,Offset LastY
  MOV DS:[SI],AX
  POP DS
 end;
 if not PA then Exit;
 restoreBackground(LX,LY);
 preserveBackground(SX,SY);
 DrawPointer(SX,SY);
end;




procedure ResetMouse;
begin
 if MouseInitialized then Exit;
 if getButtonNumber = 0 then Exit;
 asm
  XOR AX,AX
  INT 33h
 end;
 InstallHandler(@InterruptHandler,1);
 MouseInitialized := true;
 {if (SVGAMode) then SetMouseMickeyPixelRatio(16, 32)
                else SetMouseMickeyPixelRatio(8, 16);}
end;


procedure ChangePointer(var newPointer: PointerSprite; HotspotX, HotspotY:Integer);
begin
 if not mouseInitialized then Exit;
 Move(newPointer, MousePointer, POINTER_DIMENSION * POINTER_DIMENSION);
 DeltaX:=HotspotX;
 DeltaY:=HotspotY;
end;

procedure ChangePointerFromFile(PointerFileNumber: Byte);
var PointerFileHandle: File;
    Pointer: PointerSprite;
    HotspotX, HotspotY: Integer;
    PointerFileName: String;
begin
    PointerFileName := IntToStr(PointerFileNumber);
    while (length(PointerFileName)<3) do PointerFileName := '0' + PointerFileName;
    PointerFileName := PointerFileName + '.PTR';
    Assign(PointerFileHandle, PointerFileName);
    Reset(PointerFileHandle, 1);
    if (IOResult <> 0) then Exit;
    if FileSize(PointerFileHandle) <> POINTER_DIMENSION * POINTER_DIMENSION then Exit;
    BlockRead(PointerFileHandle, Pointer, POINTER_DIMENSION * POINTER_DIMENSION);
    Close(PointerFileHandle);
    ChangePointer(Pointer, 0, 0);
end;

procedure HideMouse;
begin
 if not mouseInitialized then Exit;
 if not PointerActive then Exit;
 restoreBackground(LastX,LastY);
 PointerActive:=False; 
end;

procedure ShowMouse;
VAR X,Y:Word;
    Left,Middle,Right:Boolean;
begin
    if not mouseInitialized then Exit;
    if PointerActive then Exit;
    GetMouse(X,Y,Left,Middle,Right);
    DEC(X, DeltaX);
    DEC(Y, DeltaY);
    preserveBackground(X,Y);
    DrawPointer(X,Y);
    LastX := X;
    LastY := Y;
    PointerActive:=True;
    if (not SVGAMode) then
    begin
     XRange(0,319-POINTER_DIMENSION);
     YRange(0,199-POINTER_DIMENSION);
    end
    else
    begin
     XRange(0,639-POINTER_DIMENSION);
     YRange(0,399-POINTER_DIMENSION);
    end;
end;

procedure GetMouse(var X,Y : Word; var LeftButton,CenterButton,RightButton : Boolean); 
begin
    if not mouseInitialized then Exit;
    asm
    MOV AX,3
    INT 33h
    SHR CX,1         (* In mode 13h X comes multiplied by 2, so we divide it *)
    ADD CX,DeltaX   (* Add X offset in the pointer *)
    ADD DX,DeltaY   (* Add Y offset *)
    LES DI,[X]
    MOV ES:[DI],CX
    LES DI,[Y]
    MOV ES:[DI],DX
    MOV AL,BL
    AND AL,1
    LES DI,[LeftButton]
    STOSB
    MOV AL,BL
    AND AL,2
    SHR AL,1
    LES DI,[RightButton]
    STOSB
    AND BL,4
    SHR BL,2
    LES DI,[CenterButton]
    MOV ES:[DI],BL
    end;
    {If SVGA, we undo the multiplication by 2}
    if (SVGAMode) then X :=  (X - DeltaX) * 2 + DeltaX;
end;


procedure MovePointer(X,Y : Word); 
begin
    if not mouseInitialized then Exit;
    if PointerActive then Exit;
    asm
        MOV AX,4
        MOV CX,X
        SHL CX,1
        MOV DX,Y
        INT 33h
    end;
end;

procedure XRange(Min, Max: Word); 
begin
    if not mouseInitialized then Exit;
    asm
        MOV AX,7
        MOV CX,Min;
        MOV DX,Max;
        SHL cx,1
        SHL DX,1      (* Multuply by 2 x coordinates son 13h mode works fine*)
        INT 33h       
    end;
end;    


procedure YRange(Min, Max : Word);
begin
    if not mouseInitialized then Exit;
    asm
        MOV AX,8
        MOV CX,Min
        MOV DX,Max
        INT 33h
    end;
end;


procedure InitializeMouse;
begin
 MouseInitialized := false;
 PointerActive := False;
 if (getButtonNumber > 0) then setFlag(FMOUSE, getFlag(FMOUSE) or 1)
                          else setFlag(FMOUSE, getFlag(FMOUSE) and 254);
 DeltaX := 0;
 DeltaY := 0;
end;

procedure TerminateMouse; 
begin
    if not MouseInitialized then Exit;
    asm
        XOR AX,AX
        INT 33h
    end;
end;


function MouseStatus(left, middle, right: Boolean): Byte;
var Status: Byte;
begin
 Status := 0;
 if left then Status := Status or 1;
 if right then Status := Status or 2;
 if middle then Status := Status or 4;
 MouseStatus := Status;
end;


end.


{
    Info by Joseluis Cebrián about the MOUSE condact in DAAD:

    MOUSE   flagno  op                  (Condact 0x56, replaces version 1 PROMPT)

    This condact requires two parameters. The second parameter is a
    command/operation number, similar to how GFX/SFX works:

            Command

            0       Reset/initialize the mouse
            1       Show the mouse cursor
            2       Hide the mouse cursor
            3       Get the mouse position & state
    
    The second parameter marks the first one of a table of four flags
    which are populated when command is 3 with the following info:

            Flag    Description

            n+0     Mouse button state
            n+1     Mouse X position, in 8x8 cell coordinates
            n+2     Mouse Y position, in 8x8 cell coordinates (row)
            n+3     Mouse X position, in 6x8 character coordinates

    The button state is a combination of the following values:

            Value

            1       LeftButton mouse button is down
            2       Right mouse button is down
            4       Middle mouse button is down
}

