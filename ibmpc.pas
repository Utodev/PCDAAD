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

type TWindow = packed record
                line, col, height, width: Word; (* In characters as DAAD understands it*)
                operationMode: Byte;
                currentY, currentX : Word; (* In pixels for internal use*)
                BackupCurrentY, BackupCurrentX : Word; (* In pixels for internal use*)
                INK, PAPER, BORDER : byte;
               end; 

VAR Windows :  array [0..NUM_WINDOWS-1] of TWindow;
    ActiveWindow : Byte;
    LastPrintedIsCR : boolean;

procedure Delay(seconds: real);
procedure resetWindows;
procedure startVideoMode;
procedure terminateVideoMode;
procedure ClearWindow(X, Y, Width, Height: Word; Paper: byte);
procedure Printat(line, col : word);
procedure Tab(col:word);
procedure SaveAt;
procedure BackAt;
{Writes any text to output, zero-terminated string}
procedure WriteText(Str: Pchar; AvoidTranscript: boolean);
{Same but uses a standard Pascal string}
procedure WriteTextPas(Str: String; AvoidTranscript: boolean);
procedure ReadText(var Str: String);
procedure CarriageReturn;
procedure ClearCurrentWindow;
{When pos or size of window is set, this function is called to make sure it doesn't exceed the size}
procedure ReconfigureWindow;
{Scrolls currently selected window 1 line up}
procedure ScrollCurrentWindow;
{Like CRT unit Sound}
procedure Sound(Frequency:Word); 
{Like CRT unit NoSound}
procedure Nosound;
{Like CRT unit ReadKey, but returns extended data}
function ReadKey:Word; 
{Like CRT unit Keypressed}
function Keypressed:Boolean; 

implementation

uses strings, charset, crt, parser, utils, log;

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

function Keypressed:Boolean;  Assembler;
asm
 MOV AH,1
 INT 16h
 mov AL,0 { not using SUB to avoid CPU flags being modified}
 JE @KeypressedEnd
 mov AL,1
 @KeypressedEnd:
end;

function ReadKey:Word; Assembler;
asm
 sub AH,AH
 int 16h
end;


procedure Sound(Frequency:Word); Assembler;
asm
 mov bx,sp
 mov bx,ss:[bx+6]
 mov ax,34ddh
 mov dx,0012h
 cmp dx,bx
 jnb @l1
 div bx
 mov bx,ax
 in al,61h
 test al,3
 jne @l2
 or al,3
 out 61h,al
 mov al,0b6h
 out 43h,al
 @l2:
 mov al,bl
 out 42h,al
 mov al,bh
 out 42h,al
 @l1:
end;

procedure NoSound; Assembler;
asm
 in al,61h
 and al,0fch
 out 61h,al
end;


function StrLenInPixels(var Str: String): word;
var i : byte;
    PixelCount : Word;
begin
 PixelCount := 0;
 for i:= 1 to Length(Str) do PixelCount :=  PixelCount + charsetWidth[ord(Str[i])];
 StrLenInPixels := PixelCount;
end;

procedure ReadText(var Str: String);
var key : word; 
    keyHI, keyLO :Byte;
    SaveX, SaveY : Word;
    Xlimit : Word;
    historyStr : String;
begin
 Str := '';
 SaveX := windows[ActiveWindow].currentX;
 SaveY := windows[ActiveWindow].currentY;
 Xlimit := (windows[ActiveWindow].col +  windows[ActiveWindow].width) * 8; {First pixel out of the window}
 repeat
   while not Keypressed do;
   key := ReadKey;
   keyHI := (key and $FF00) SHR 8;
   keyLO := key and $FF;

   if (keyLO>=32) and (keyLO<=255) then 
   begin
    {Avoid input exceeding the current line} 
    if (StrLenInPixels(Str) + charsetWidth[keyLo] + SaveX  < Xlimit) and (length(Str)<255) 
        then Str := Str + chr(keyLo) {printable characters}
   end;

  if (keyLO = 8) and (Str<>'') then 
  begin
    ClearWindow(SaveX + StrLenInPixels(Str) - charsetWidth[byte(Str[Length(Str)])], 
                  SaveY, charsetWidth[byte(Str[Length(Str)])], 
                  8 , windows[ActiveWindow].PAPER);
    Str := Copy(Str, 1, Length(Str)-1); {backspace}
  end;
  if keyLO = 9 then {tab} (* Pending: make this work with arrow up/down *)
  begin
   historyStr := getNextOrderHistory; 
   if historyStr<> str then 
   begin
    ClearWindow(SaveX, SaveY, Xlimit-SaveX , 8, windows[ActiveWindow].PAPER);
    Str := historyStr;
   end;
  end; 

  windows[ActiveWindow].currentX := SaveX;
  windows[ActiveWindow].currentY := SaveY;
  WriteTextPas(Str, true); {true -> Avoid transcript}
 until (keyLO = 13) and (Str<>''); {Intro and not empty}
 CarriageReturn;
 addToOrderHistory(Str);
 TranscriptPas(Str + #13#10);
end;

function getVGAAddr(X, Y: word): word;
begin
 getVGAAddr := X + Y * 320;
end;

procedure ClearWindow(X, Y, Width, Height: Word; Paper: byte);
var i : word;
begin
 for i := 0 to Height - 1 do 
  FillChar(mem[$a000:320*(y+i)+X], Width, Paper);
end;

procedure ClearCurrentWindow;
begin
{$ifdef VGA}
   ClearWindow(windows[ActiveWindow].col * 8, windows[ActiveWindow].line * 8,
     windows[ActiveWindow].width * 8, windows[ActiveWindow].height * 8, windows[ActiveWindow].PAPER);
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

(* FALTA SOPORTE DEL UPPER FONT  y de las secuencias #r #k, etc*)
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
 NextChar(width); {Move pointer to next printing position}
 end;
 {$else}
 Write(C);
 {$endif}
end;

procedure WriteWord(Str:String);
var i: integer;
    Xlimit : Word;
    
begin
  Xlimit := (windows[ActiveWindow].col +  windows[ActiveWindow].width) * 8; {First pixel out of the window}
  if (StrLenInPixels(Str) + windows[ActiveWindow].currentX >= Xlimit) then CarriageReturn;
  if not (LastPrintedIsCR  and (Str=' ')) then 
      for i:=1 to Length(Str) do WriteChar(Str[i]);
  LastPrintedIsCR := false;
end;

(* FALTA: controlar cuando sale mucho texto de golpe para que se hagan pausas *)
procedure WriteText(Str: Pchar; AvoidTranscript: boolean);
var i: integer;
    AWord : String;
begin
 LastPrintedIsCR := false;
 (*FALTA: Hay que controlar cuando sale mucho texto de golpe para que haga pausas *)
 if not AvoidTranscript then Transcript(Str);
 i :=0 ;
 Aword := '';
 while (Str[i]<>#0) do 
 begin
  case (Str[i]) of
    #13: begin
          WriteWord(AWord);
          AWord := '';
          CarriageReturn;
         end; 
    ' ': begin
          WriteWord(AWord);
          AWord := '';
          WriteWord(' ');
         end; 
    else AWord := Aword + Str[i];
  end; {case}
  i := i + 1;
 end; 
 WriteWord(Aword);
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
LastPrintedIsCR := true;
end;

procedure WriteTextPas(Str: String; AvoidTranscript: boolean);
var temp : array[0..256] of char;
begin
 StrPCopy(temp, Str) ;
 WriteText(temp, AvoidTranscript);
end;

begin
 LastPrintedIsCR := false;
end.
