
{$I SETTINGS.INC}

unit ibmpc;
(* IBM PC specific functions *)

interface

const NUM_WINDOWS = 8;
      NUM_COLUMNS = 40; {40 colums of 8x8, but proportional fonts will do better}
      NUM_LINES=25;

type TWindow = packed record
                line, col, height, width: Word; (* In characters as DAAD understands it*)
                operationMode: Byte;
                currentY, currentX : Word; (* In pixels for internal use*)
                BackupCurrentY, BackupCurrentX : Word; (* In pixels for internal use*)
                INK, PAPER, BORDER : byte;
                LastPauseLine: Word; (* Line where the text stopped for the user to read last *)
               end; 

VAR Windows :  array [0..NUM_WINDOWS-1] of TWindow;
    ActiveWindow : Byte;
    LastPrintedIsCR : boolean;
    CharsetShift : Byte;
    

function Extern(A, B: Byte): boolean;
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
{Wait for vertical retrace}
procedure WaitVRetrace;

implementation

uses strings, charset, crt, parser, utils, log, ddb, objects, flags;

var ExternPTR: Pointer;

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

function PatchStr(Str: String): String;
var i: word;
    FinalStr: String;
begin
 FinalStr :='';
 for i:= 1 to Length(Str) do 
 case Str[i] of
   { Original DAAD characters }
   '¦': FinalStr := FinalStr + #16;
   '­': FinalStr := FinalStr + #17;
   '¨': FinalStr := FinalStr + #18;
   '®': FinalStr := FinalStr + #19;
   '¯': FinalStr := FinalStr + #20;
   ' ': FinalStr := FinalStr + #21;
   '‚': FinalStr := FinalStr + #22;
   '¡': FinalStr := FinalStr + #23;
   '¢': FinalStr := FinalStr + #24;
   '£': FinalStr := FinalStr + #25;
   '¤': FinalStr := FinalStr + #26;
   '¥': FinalStr := FinalStr + #27;
   '‡': FinalStr := FinalStr + #28;
   '€': FinalStr := FinalStr + #29;
   '': FinalStr := FinalStr + #30;
   '': FinalStr := FinalStr + #31;
   { New characters}
   '…': FinalStr := FinalStr + #$0e#16#$0f;
   chr(198): FinalStr := FinalStr + #$0e#17#$0f; {'Portuguese a with curly tilde' in codepage 850}
   '„': FinalStr := FinalStr + #$0e#18#$0f;
   'ƒ': FinalStr := FinalStr + #$0e#19#$0f;

   'Š': FinalStr := FinalStr + #$0e#20#$0f;
   '‰': FinalStr := FinalStr + #$0e#21#$0f;
   'ˆ': FinalStr := FinalStr + #$0e#22#$0f;

   '': FinalStr := FinalStr + #$0e#23#$0f;
   '‹': FinalStr := FinalStr + #$0e#24#$0f;
   'Œ': FinalStr := FinalStr + #$0e#25#$0f;

   '•': FinalStr := FinalStr + #$0e#26#$0f;
   chr(229): FinalStr := FinalStr + #$0e#27#$0f; {'Portuguese o with curly tilde' in codepage 850}
   '”': FinalStr := FinalStr + #$0e#28#$0f;
   '“': FinalStr := FinalStr + #$0e#29#$0f;

   '—': FinalStr := FinalStr + #$0e#30#$0f;
   '–': FinalStr := FinalStr + #$0e#31#$0f;
    
    chr(225): FinalStr := FinalStr + #$0e#35#$0f; {German 'á', eszett in codepage 850 and 437 rather than eszett letter}

    else FinalStr := FinalStr + Str[i];
 end;
 PatchStr := FinalStr;
end;


function StrLenInPixels(Str: String): word;
var i : byte;
    PixelCount : Word;
    ShiftStatus: Byte;
begin
 PixelCount := 0;
 shiftStatus := CharsetShift;
 
 (* To properly check length, we need to make sure we use the proper characters *)
 Str := PatchStr(Str); 

 for i:= 1 to Length(Str) do 
 begin
  case  ord(Str[i]) of 
   $0B: PixelCount := PixelCount + 8;  {Forced blank space}
   $0E: ShiftStatus := 128;
   $0F: ShiftStatus := 0;
   $10..$FF : PixelCount :=  PixelCount + charsetWidth[(ord(Str[i]) + ShiftStatus) mod 256]; {All other printable characters}
  end;
 end;   
 StrLenInPixels := PixelCount;
end;



procedure ReadText(var Str: String);
var key : word; 
    keyHI, keyLO :Byte;
    SaveX, SaveY : Word;
    Xlimit : Word;
    historyStr : String;
    PatchedStr : String; (* Contains the String with international characters already patched *)
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
    if (StrLenInPixels(Str) + StrLenInPixels(char(keyLo)+'') + SaveX  < Xlimit) and (length(Str)<255) 
        then Str := Str + chr(keyLo) {printable characters}
   end;

  if (keyLO = 8) and (Str<>'') then 
  begin
    ClearWindow(SaveX + StrLenInPixels(Str) - StrLenInPixels(''+Str[Length(Str)]), 
                  SaveY, StrLenInPixels(''+Str[Length(Str)]), 
                  8 , windows[ActiveWindow].PAPER);
    Str := Copy(Str, 1, Length(Str)-1); {backspace}
  end;
  (* Pending: make history of order accessible with arrow up/down instead of tab *)
  if keyLO = 9 then {tab} 
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
  PatchedStr := PatchStr(Str);
  WriteTextPas(PatchedStr, true); {true -> avoid transcript}
 until (keyLO = 13) and (Str<>''); {Intro and not empty}
 CarriageReturn;
 addToOrderHistory(Str);
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
   ClearWindow(windows[ActiveWindow].col * 8, windows[ActiveWindow].line * 8,
     windows[ActiveWindow].width * 8, windows[ActiveWindow].height * 8, windows[ActiveWindow].PAPER);

   windows[ActiveWindow].currentY := windows[ActiveWindow].line * 8;
   windows[ActiveWindow].currentX := windows[ActiveWindow].col * 8;
   windows[ActiveWindow].LastPauseLine := 0;
end;

PROCEDURE startVideoMode; Assembler;
ASM
 MOV AX, $13
 INT $10
END;


PROCEDURE terminateVideoMode; Assembler;
ASM
 MOV AX, $03
 INT $10
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
 if (col < Windows[ActiveWindow].width) then Windows[ActiveWindow].CurrentX := (Windows[ActiveWindow].col + col) * 8
                                        else Tab(0);
{Tested in ZX Spectrum interpreter: when the column provided exceeds the window, 
then it's like TAB 0,  beginning of line}                                        
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
  {0. Check if too much text listed in order to pause if so}
  if (windows[ActiveWindow].LastPauseLine >= windows[ActiveWindow].height) then 
  begin
   while not Keypressed do;
   i := ReadKey; {Discard key pressed}
   windows[ActiveWindow].LastPauseLine := 0;
  end; 

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
 case byte(c) of
  $0E : CharsetShift := 128; {#g}
  $0F : CharsetShift := 0; {#t}
  $0B : ClearCurrentWindow; {#b}
  $0C : begin while not keypressed do; i := Readkey; end; {#k}
  else
  begin
    baseAddress := getVGAAddr(windows[ActiveWindow].currentX , windows[ActiveWindow].currentY);
    width := charsetWidth[(byte(c) + CharsetShift) MOD 256];
    if (windows[ActiveWindow].currentX + width >= (windows[ActiveWindow].col + windows[ActiveWindow].width) * 8 ) then 
    begin
      NextChar(width);
      WriteChar(c);
    end
    else
    begin
        for i := 0 to 7 do
        begin
        scan := charsetData[(ord(c) + CharsetShift) MOD 256 * 8 + i];  {Get definition for this scanline}
        scan := scan shr (8-width);
        for j := 0 to width-1 do
        begin
          if (scan and (1 shl (width - j)) <> 0) then mem[$a000:baseAddress + i * 320 + j] := windows[ActiveWindow].INK
                                                else mem[$a000:baseAddress + i * 320 + j] := windows[ActiveWindow].PAPER;
        end;
        end;
    NextChar(width); {Move pointer to next printing position}
    end;
   end
 end; {case of}
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

procedure WriteText(Str: Pchar; AvoidTranscript: boolean);
var i: integer;
    AWord : String;
begin
 LastPrintedIsCR := false;
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
  windows[ActiveWindow].currentX := windows[ActiveWindow].col * 8;
  windows[ActiveWindow].currentY := windows[ActiveWindow].currentY + 8;
  windows[ActiveWindow].LastPauseLine := windows[ActiveWindow].LastPauseLine + 1;
  {if out of boundary scroll window}
  if (windows[ActiveWindow].currentY >= (windows[ActiveWindow].line + windows[ActiveWindow].height) * 8 ) then 
   ScrollCurrentWindow;
  LastPrintedIsCR := true;
end;

procedure WriteTextPas(Str: String; AvoidTranscript: boolean);
var temp : array[0..256] of char;
begin
 StrPCopy(temp, Str) ;
 WriteText(temp, AvoidTranscript);
end;

procedure WaitVRetrace; assembler;
asm                                            
  mov dx,3dah;
  @r1: in al,dx; test al,8; jnz @r1
  @r2: in al,dx; test al,8; jz @r2
end;

procedure InitializeExtern;
var SizeExtern : longint;
    readBytes: word;
    F: FILE;
    dir, des_dir, seg_dir:longint;
begin
 Assign(F,'DAAD.EXT');
 Reset(F,1);
 if IOResult=0 then
 begin
  TranscriptPas('Loading extern file...'#13);
   SizeExtern:=system.FileSize(F)+20;
   getmem(ExternPTR,SizeExtern);
   dir:=longint(ExternPTR);
   des_dir:=dir AND $0000FFFF;
   seg_dir:=dir AND $FFFF0000;
   des_dir:=(des_dir+16) SHR 4;
   ExternPTR:=pointer(seg_dir+(des_dir SHL 16));
   BlockRead(F,ExternPTR^,SizeExtern-20,readBytes);
   Close(F);
 end else TranscriptPas('Failed to load DAAD.EXT'#13);
end;   


function Extern(A, B: Byte): boolean;
var PObj, Pflags: Pointer;
begin
 Extern := false;
 if ExternPTR = nil  THEN InitializeExtern;
 if ExternPTR = nil then exit; {No Extern to load}
 TranscriptPas('Extern Execution...'#13);
 {$F+}   {Force Far calls}
 PObj := @objLocations;
 PFlags := @flagsArray;
 Extern := true;
 asm
    PUSH DS
    MOV AL,A  {Tengo dudas des i al hacer los LDS de tres cosas al 
    final DS apunta a a vete a saber donde porque no están los tres en el mismo segmento}
    MOV AH, B   {además, podriamos prescindir del DDBRAM porque si quiren lo pueden cargar desde el extern}
    LDS BX, [PFlags] {Pointer to the flags}
    LDS CX, [PObj]   {Pointer to object locations}
    CALL ExternPTR
    POP DS
 end;
{$F-}
 TranscriptPas('Extern Completed...'#13);
end;


begin
 LastPrintedIsCR := false;
 CharsetShift := 0;
 ActiveWindow := 0;
 resetWindows;
 ExternPTR := nil;
end.
