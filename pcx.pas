{$I SETTINGS.INC}

UNIT PCX;

{
    This unit is able to load a 256 color indexed PCX file directly into video RAM
}

interface



{Loads PCX file into buffer}
function LoadPCX( ImageNumber: Word; SVGAMode: boolean): boolean;
{This function really copies the buffer into the screen if option = 0, and clears the are otherwise}
procedure DisplayPCX(X, Y, width, height: word; option: Byte; SVGAMode: boolean);
{This function initalizes the sceen Buffers}
procedure InitializePCX(SVGAMode: boolean);
{This function clears the PCX system}
procedure ClearPCX;

implementation

uses utils, log,readbuff, ibmpc, vesa, palette; 

type TScreenBuffer = array[0..63999] of Byte;

var ScreenBuffer: array [0..3] of ^TScreenBuffer;
    NumBuffers: byte;
    LatestPCXFileSize : Longint;
    LatestPCXHeight, LatestPCXWidth :Word;
    PaletteBuffer :  array[0..767] of Byte;
    lineWidth : Word;

procedure InitializePCX(SVGAMode: boolean);
var i : byte;
begin
{$ifndef lowmem} {if defined lowmem, we don't use pictures, to save the RAM required
                for the buffers, and being able to debug under Turbo Pascal IDE}
 if (SVGAMode) then NumBuffers := 4 else NumBuffers := 1;
 if (SVGAMode) then lineWidth := 640 else lineWidth := 320;
 for i:=0 to NumBuffers-1 do GetMem(ScreenBuffer[i], Sizeof(TScreenBuffer))
 {$endif}
end;      

procedure ClearPCX;
var i : byte;
begin
{$ifndef lowmem}
 for i:=0 to NumBuffers-1 do FreeMem(ScreenBuffer[i], Sizeof(TScreenBuffer))
 {$endif}
end;


function LoadPCX(ImageNumber: Word; SVGAMode: boolean): boolean;
var Aux : Byte;
    AuxWord : Word;
    ImgWidth, ImgHeight : Word;
    CurrentPtr : Longint;
    Color, Reps : Byte;
    CurrentX, CurrentY : Longint;
    ImageFileName : String;
    i, j: Longint;
    Success : boolean;
    DIVV, MODD : Longint;
begin

{$ifndef lowmem}
 if (ImageNumber = 65535) then 
 begin
  ImageFileName := 'DAAD';
 end
 else
 begin
  ImageFileName := IntToStr(ImageNumber);
  while (length(ImageFileName)<3) do ImageFileName := '0' + ImageFileName;
 end; 
 
 Success := readbuff.fileopen(ImageFileName + '.vga');
 if (not Success) then
 begin
  Success := readbuff.fileopen(ImageFileName + '.pcx');
  if (not Success) then
  begin
   LatestPCXFileSize := 0;
   LoadPCX := false;
   exit;
  end; 
 end; 


 Aux := readbuff.fileGetByte(readbuff.bufferFileSize - 769);
 
 if (Aux <> $0C) then  {Mark of 256 color palette}
 begin
  readbuff.fileclose;
  LatestPCXFileSize := 0;
  LoadPCX := false;
  exit;
 end; 

 {Clear the image buffer}
 for i:=0 to Numbuffers -1  do FillChar(ScreenBuffer[i]^, Sizeof(TScreenBuffer), 0);

 { Get the real dimension of the file}{Note: Keep this strange order in this calculation, it's made for faster file reading}
 ImgWidth := - (readbuff.fileGetByte(4) + 256 * readbuff.fileGetByte(5))  
                + readbuff.fileGetByte(8) + 256 * readbuff.fileGetByte(9) + 1;
 ImgHeight := readbuff.fileGetByte(10) + 256 * readbuff.fileGetByte(11) 
               - (readbuff.fileGetByte(6) + 256 * readbuff.fileGetByte(7)) + 1;

if ((SVGAmode) and ((ImgWidth > 640) or (ImgHeight > 400)) 
     or ((not SVGAmode) and ((ImgWidth > 320) or (ImgHeight > 200)))) then
begin
  readbuff.fileclose;
  LatestPCXFileSize := 0;
  LoadPCX := false;
  exit;
 end; 

 { Fix VGA Palette. It's a 18 bit DAC, 6+6+6 and PCX format saves 
  each 6 bits in a byte, but aligned to the most significative bit}
 for AuxWord := 0 to 767 do 
 begin
  PaletteBuffer[AuxWord] := readbuff.fileGetByte(readbuff.bufferFileSize - 768 + AuxWord) SHR 2;
 end; 


 { Load the pixels}
 CurrentX := 0;
 CurrentY := 0;
 CurrentPtr := 128;


 repeat
  
  Color := readbuff.fileGetByte(CurrentPtr);
  if (Color AND $C0) = $C0 then       { If color > 192 it's not a color but a rep count }
  begin
   Reps := Color AND $3F;
   Inc(CurrentPtr); {CurrentPtr := CurrentPtr + 1;}
   Color := readbuff.fileGetByte(CurrentPtr);
  end
  else Reps := 1;
  Inc(CurrentPtr); {CurrentPtr := CurrentPtr + 1;}
  while  Reps>0 do
  begin
    Dec(Reps); {Reps := Reps -1;}
    DIVV := (lineWidth * CurrentY + CurrentX) DIV Sizeof(TScreenBuffer); {calculate wich buffer}
    MODD := (lineWidth * CurrentY + CurrentX) MOD Sizeof(TScreenBuffer); 
    ScreenBuffer[DIVV]^[MODD] := Color;
    Inc(CurrentX); {CurrentX := CurrentX + 1;}
    if (CurrentX  >= ImgWidth) then
    begin
      CurrentX := 0;
      Inc(CurrentY); {CurrentY := CurrentY + 1;}
    end;
  end;  
 until (CurrentY >= ImgHeight);


 readbuff.fileclose;
 LatestPCXFileSize := readbuff.bufferFileSize;
 LatestPCXHeight := ImgHeight;
 LatestPCXWidth := ImgWidth;
 {$endif}
 LoadPCX := true;
end;


procedure DisplayPCX(X, Y, width, height: word; option: Byte; SVGAMode: boolean);
var i, offset : Longint;
    DIVV : word;
    MODD: word;
    ApplyableHeight, ApplyableWidth : Word;
    
    
begin
{$ifndef lowmem}
if (SVGAmode) then
begin
   width := width SHL 1;
   height := height SHL 1;
   X := X SHL 1;
   Y := Y SHL 1;
end;  

 if (option=0) then
 begin
  if (LatestPCXFileSize <> 0) then
  begin

    ApplyableHeight := min(height, LatestPCXHeight);
    ApplyableWidth := min(width, LatestPCXWidth);

    {Now we really paint the picture}
    WaitVRetrace;
    {Set palette}
    SetAllPalette(PaletteBuffer);
    { Copy from doble buffer}
    if (SVGAMode) then
    begin
      VESARectangle(X, Y, ApplyableWidth, ApplyableHeight, windows[ActiveWindow].PAPER);
      for i:= 0 to ApplyableHeight - 1 do
      begin
          DIVV := (i*640) DIV Sizeof(TScreenBuffer); {calculate wich buffer}
          MODD := (i*640) MOD Sizeof(TScreenBuffer); {calculate wich offset}
          VESAPutImage(X, Y + i, ApplyableWidth, 1, ScreenBuffer[DIVV]^[MODD],0);
          if (ApplyableWidth < width) then 
           VESARectangle(X + ApplyableWidth, Y + i, width - ApplyableWidth, 1, windows[ActiveWindow].PAPER);

      end;
    end
    else
    begin
      offset := 0;      
      for i:= 0 to LatestPCXHeight - 1 do
      begin
          Move(ScreenBuffer[0]^[offset], Mem[$A000:(Y+i)*lineWidth + X], ApplyableWidth);
          if (ApplyableWidth < width) then 
           FillChar(Mem[$A000:(Y+i)*lineWidth + X + ApplyableWidth], width - ApplyableWidth, windows[ActiveWindow].PAPER);
          Inc(offset,lineWidth);
      end;
    end; 
   end 
 end
 else (* option <> 0 *)
 begin
  if SVGAMode then ClearWindow(X SHR 1, Y  SHR 1, width SHR 1, height  SHR 1, Windows[ActiveWindow].PAPER)
              else ClearWindow(X, Y, width, height, Windows[ActiveWindow].PAPER); 
 end;
 {$endif}
end;

begin
 LatestPCXFileSize :=0;
end.
