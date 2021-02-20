unit graph;




interface
const NUM_WINDOWS = 8;
{$ifdef VGA}
      BIOS_VIDEO_MODE = $13;
      NUM_COLUMNS = 51;
      NUM_LINES=25;
{$else}
      BIOS_VIDEO_MODE = $03;
      NUM_COLUMNS = 80;
      NUM_LINES=25;
{$endif}

type TWindow = record
                line, col, height, width: Word;
                operationMode: Byte;
               end; 

VAR INK, PAPER, BORDER: byte;
    Windows :  array [0..NUM_WINDOWS-1] of TWindow;
    ActiveWindow : Byte;
    CurrentLine, CurrentCol : Word;
    BackupCurrentLine, BackupCurrentCol : Word;

procedure resetWindows;
procedure startVideoMode;
procedure terminateVideoMode;
procedure Printat(line, col : word);
procedure SaveAt;
procedure BackAt;

implementation

PROCEDURE startVideoMode; Assembler;
ASM
 MOV AX, BIOS_VIDEO_MODE
 INT $10
END;

PROCEDURE terminateVideoMode; Assembler;
ASM
 MOV AX, $03
 INT $10
END;

procedure Printat(line, col : word);
begin
 if (line < NUM_LINES) and (col<NUM_COLUMNS) then
 begin
    CurrentLine := line;
    CurrentCol := col;
 end;
end; 

procedure SaveAt;
begin
 BackupCurrentLine := CurrentLine;
 BackupCurrentCol := CurrentCol;
end;

procedure BackAt;
begin
  CurrentLine := BackupCurrentLine;
  CurrentCol := BackupCurrentCol;
end;


procedure resetWindows;
var i : word;
begin
 for i:= 0 to NUM_WINDOWS - 1 do 
 begin
  Windows[i].line := 0;
  Windows[i].col := 0;
  Windows[i].height := NUM_ROWS;
  Windows[i].width := NUM_COLUMNS;
  Windows[i].operationMode := 0;
 end; 
end;

end.
