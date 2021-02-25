unit ibmpc;
(* IBM PC specific functions *)

interface

const NUM_WINDOWS = 8;
{$ifdef VGA}
      NUM_COLUMNS = 53;
      NUM_LINES=25;
{$else}
      NUM_COLUMNS = 80;
      NUM_LINES=25;
{$endif}

type TWindow = record
                line, col, height, width: Word;
                operationMode: Byte;
                currentLine, currentCol : Word;
                BackupCurrentLine, BackupCurrentCol : Word;
               end; 

VAR INK, PAPER, BORDER: byte;
    Windows :  array [0..NUM_WINDOWS-1] of TWindow;
    ActiveWindow : Byte;

function GetKey:Word; 
procedure resetWindows;
procedure startVideoMode;
procedure terminateVideoMode;
procedure Printat(line, col : word);
procedure Tab(col:word);
procedure SaveAt;
procedure BackAt;
procedure WriteText(Str: Pchar);
procedure CarriageReturn;
procedure ClearCurrentWindow;


implementation

uses strings;


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


procedure ClearCurrentWindow;
begin
 (* FALTA *)
end;

PROCEDURE startVideoMode; Assembler;
ASM
{$ifdef VGA}
 MOV AX, $13
 INT $10
{$endif}
END;


PROCEDURE terminateVideoMode; Assembler;
ASM
{$ifdef VGA}
 MOV AX, $03
 INT $10
{$endif}
END;

procedure Printat(line, col : word);
begin
 if (line < Windows[ActiveWindow].height) and (col < Windows[ActiveWindow].width) then
 begin
    Windows[ActiveWindow].CurrentLine := line;
    Windows[ActiveWindow].CurrentCol := col;
 end;
end; 

procedure Tab(col:word);
begin
 if (col < Windows[ActiveWindow].width) then Windows[ActiveWindow].CurrentCol := col;
end; 

procedure SaveAt;
begin
 Windows[ActiveWindow].BackupCurrentLine := Windows[ActiveWindow].currentLine;
 Windows[ActiveWindow].BackupCurrentCol := Windows[ActiveWindow].CurrentCol;
end;

procedure BackAt;
begin
  Windows[ActiveWindow].CurrentLine := Windows[ActiveWindow].BackupCurrentLine;
  Windows[ActiveWindow].CurrentCol := Windows[ActiveWindow].BackupCurrentCol;
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
 end; 
end;

procedure WriteText(Str: Pchar);
var i: integer;
begin
 i :=0 ;
 while (Str[i]<>#0) do 
 begin
  write(Str[i]);
  i := i + 1;
 end; 
 {Write(Str);}
end;

procedure CarriageReturn;
begin
 (* FALTA *)
end;


end.
