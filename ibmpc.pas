{$I SETTINGS.INC}

unit ibmpc;
(* IBM PC specific functions *)

interface

const NUM_WINDOWS = 8;
{$ifdef VGA}
      NUM_COLUMNS = 40; {40 colums of 8x8, but proportional fonts will do better}
      NUM_LINES=25;
{$else}
      NUM_COLUMNS = 80;
      NUM_LINES=25;
{$endif}

type TWindow = record
                line, col, height, width: Word; (* In characters as DAAD understands it*)
                operationMode: Byte;
                currentY, currentX : Word; (* In pixels for internal use*)
                BackupCurrentY, BackupCurrentX : Word; (* In pixels for internal use*)
                INK, PAPER, BORDER : byte;
               end; 

VAR Windows :  array [0..NUM_WINDOWS-1] of TWindow;
    ActiveWindow : Byte;

function GetKey:Word; 
procedure Delay(seconds: real);
procedure resetWindows;
procedure startVideoMode;
procedure terminateVideoMode;
procedure Printat(line, col : word);
procedure Tab(col:word);
procedure SaveAt;
procedure BackAt;
procedure WriteText(Str: Pchar);
procedure WriteTextPas(Str: String);
procedure ReadText(var Str: String);
procedure CarriageReturn;
procedure ClearCurrentWindow;
{When pos or size of window is set, this function is called to make sure it doesn't exceed the size}
procedure ReconfigureWindow;
{Scrolls currently selected window 1 line up}
procedure ScrollCurrentWindow;

implementation

uses strings, charset;

function getTicks: word; Assembler;
asm
 SUB AH,AH
 INT $1A
 MOV AX, DX
end;

procedure Delay(seconds: real);
{ The getTicks funcion returns just the lower value of BIOS timer ticks.
  A tick happens 18.2 times per second, so the tick counter overflows 
  every hour. To avoid misscalculation when the system notices the 
  current tick count is smaller than the original one, it considers an
  overflow happened, and adds $10000 to proparly check. Despite that is
  very unlikely to happen (only happens once an hour and the delay has
  to happen just before the overflow)}
var initialTicks, currentTicks : longint;
begin
 initialTicks := getTicks;
 repeat
  currentTicks := getTicks;
  if (currentTicks<getTicks) then currentTicks := currentTicks and $10000;
 until (currentTicks - initialTicks) / 18.2 >= seconds;
end;

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


procedure ReadText(var Str: String);
var key : word; 
    SaveX, SaveY : Word;
begin
 Str := '';
 SaveX := windows[ActiveWindow].currentX;
 SaveY := windows[ActiveWindow].currentY;
 repeat
  key := GetKey;
  if (key>=32) and (key<=255) then Str := Str + chr(key); {printable characters}
  if key = 8 then Str := Copy(Str, 1, Length(Str)-1); {backspace}
  windows[ActiveWindow].currentX := SaveX;
  windows[ActiveWindow].currentY := SaveY;
  WriteTextPas(Str + '  '); {the spaces are there to clear content when backspace pressed}
 until key = 13; {Intro}
end;

function getVGAAddr(X, Y: word): word;
begin
 getVGAAddr := X + Y * 320;
end;

procedure ClearCurrentWindow;
var  i: integer;
     x, y : word;
     widthInPixels : word;
     paper: byte;
begin
{$ifdef VGA}
   x := windows[ActiveWindow].col * 8;
   y := windows[ActiveWindow].line * 8;
   widthInPixels := windows[ActiveWindow].width * 8;
   paper  := windows[ActiveWindow].PAPER;
   for i:=  0 to windows[ActiveWindow].height * 8 do
   begin
    FillChar(mem[$a000: 320 * y + x], widthInPixels, char(paper));  
    y := y + 1;
   end;
   windows[ActiveWindow].currentY := windows[ActiveWindow].line * 8;
   windows[ActiveWindow].currentX := windows[ActiveWindow].col * 8;
 {$else}
  startVideoMode;
 {$endif}
end;

PROCEDURE startVideoMode; Assembler;
ASM
{$ifdef VGA}
 MOV AX, $13
{$else }
 MOV AX, $03
{$endif}
 INT $10
END;


PROCEDURE terminateVideoMode; Assembler;
ASM
{$ifdef VGA}
 MOV AX, $03
 INT $10
{$endif}
END;

procedure ReconfigureWindow;
begin
 if (Windows[ActiveWindow].col + Windows[ActiveWindow].width > NUM_COLUMNS) then
    Windows[ActiveWindow].width := NUM_COLUMNS - Windows[ActiveWindow].col;

 if (Windows[ActiveWindow].line + Windows[ActiveWindow].height > NUM_LINES) then
    Windows[ActiveWindow].height := NUM_LINES - Windows[ActiveWindow].line;
end;

procedure Printat(line, col : word);
begin
(* Falta comprobar este if porque no me cuadra mucho*)
 if (line < Windows[ActiveWindow].height) and (col < Windows[ActiveWindow].width) then
 begin
    Windows[ActiveWindow].CurrentY := line * 8;
    Windows[ActiveWindow].CurrentX := col * 8;
 end;
end; 

procedure Tab(col:word);
begin
 if (col < Windows[ActiveWindow].width) then Windows[ActiveWindow].CurrentX := col * 8;
end; 

procedure SaveAt;
begin
 Windows[ActiveWindow].BackupCurrentY := Windows[ActiveWindow].currentY;
 Windows[ActiveWindow].BackupCurrentX := Windows[ActiveWindow].CurrentX;
end;

procedure BackAt;
begin
  Windows[ActiveWindow].CurrentY := Windows[ActiveWindow].BackupCurrentY;
  Windows[ActiveWindow].CurrentX := Windows[ActiveWindow].BackupCurrentX;
end;


procedure resetWindows;
var i : word;
begin
 for i:= 0 to NUM_WINDOWS - 1 do 
 begin
  Windows[i].line := 0;
  Windows[i].col := 0;
  Windows[i].height := NUM_LINES;
  Windows[i].width := NUM_COLUMNS;
  Windows[i].operationMode := 0;
  Windows[i].currentX := 0;
  Windows[i].currentY := 0;
  Windows[i].backupCurrentX := 0;
  Windows[i].backupCurrentY := 0;
  Windows[i].PAPER := 0;
  Windows[i].BORDER := 0;
  Windows[i].INK := 15;
 end; 
end;



procedure ScrollCurrentWindow;
var i, baseAddress, baseaddress2, linesToScroll, windowWidthInPixels : word;
begin
  {1. Move window up}
   baseAddress := getVGAAddr(windows[ActiveWindow].col * 8 , (windows[ActiveWindow].line + 1) * 8); 
   linesToScroll := (windows[ActiveWindow].height -1) * 8; 
   windowWidthInPixels := windows[ActiveWindow].width * 8;
   baseaddress2 := baseAddress - 8 * 320;
   for i := 0 to linesToScroll - 1 do 
   begin
    Move(mem[$a000:baseAddress], mem[$a000:baseAddress2], windowWidthInPixels);
    baseAddress := baseAddress + 320;
    baseAddress2 := baseAddress2 + 320;
   end; 

   {2. Fill new empty space at the bottom with paper colour}
   baseAddress := getVGAAddr(windows[ActiveWindow].col * 8 ,  
          (windows[ActiveWindow].line + windows[ActiveWindow].height -1) * 8); 
   for i := 0 to 7 do FillChar(Mem[$a000: baseAddress + i *320], windowWidthInPixels, chr(windows[ActiveWindow].PAPER));  
   {3. Update cursor}
   windows[ActiveWindow].currentY := windows[ActiveWindow].currentY - 8; 
   windows[ActiveWindow].currentX := windows[ActiveWindow].col * 8; 

end;


procedure NextChar(width: word);
begin
 {Increase X}
 windows[ActiveWindow].currentX := windows[ActiveWindow].currentX + width; 
 {If out of boundary increase Y}
 if (windows[ActiveWindow].currentX >= (windows[ActiveWindow].col + windows[ActiveWindow].width) * 8 ) then  
 begin
  windows[ActiveWindow].currentX := windows[ActiveWindow].col * 8;
  windows[ActiveWindow].currentY := windows[ActiveWindow].currentY + 8;
  {if out of boundary scroll window}
  if (windows[ActiveWindow].currentY >= (windows[ActiveWindow].line + windows[ActiveWindow].height) * 8 ) then
    ScrollCurrentWindow;
 end;
end;

procedure WriteChar(c: char);
var i, j : word;
    baseAddress : word;
    scan: byte;
    width :  byte;
begin
 {$ifdef VGA}
 baseAddress := getVGAAddr(windows[ActiveWindow].currentX , windows[ActiveWindow].currentY);
 width := charsetWidth[byte(c)];
 if (windows[ActiveWindow].currentX + width >= (windows[ActiveWindow].col + windows[ActiveWindow].width) * 8 ) then 
 begin
   NextChar(width);
   WriteChar(c);
 end
 else
 begin
    for i := 0 to 7 do
    begin
    scan := charsetData[ord(c) * 8 + i];  {Get definition for this scanline}
    scan := scan shr (8-width);
    for j := 0 to width-1 do
    begin
      if (scan and (1 shl (width - j)) <> 0) then mem[$a000:baseAddress + i * 320 + j] := windows[ActiveWindow].INK
                                    else mem[$a000:baseAddress + i * 320 + j] := windows[ActiveWindow].PAPER;
    end;
    end;
 end;
 NextChar(width); {Move pointer to next printing position}
 {$else}
 Write(C);
 {$endif}
end;

procedure WriteText(Str: Pchar);
var i: integer;
begin
 i :=0 ;
 while (Str[i]<>#0) do 
 begin
  if (Str[i]=#13) then CarriageReturn
                  else writechar(Str[i]);
  i := i + 1;
 end; 
end;

procedure CarriageReturn;
begin
{$ifdef VGA}
  windows[ActiveWindow].currentX := windows[ActiveWindow].col * 8;
  windows[ActiveWindow].currentY := windows[ActiveWindow].currentY + 8;
  {if out of boundary scroll window}
  if (windows[ActiveWindow].currentY >= (windows[ActiveWindow].line + windows[ActiveWindow].height) * 8 ) then 
   ScrollCurrentWindow;
{$else}
WriteText(''#10);
{$endif}
end;

procedure WriteTextPas(Str: String);
var temp : array[0..256] of char;
begin
 StrPCopy(temp, Str + #13) ;
 WriteText(temp);
end;


end.
