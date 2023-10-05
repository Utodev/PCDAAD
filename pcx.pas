{$I SETTINGS.INC}
UNIT PCX;

{
    This unit is able to load a 256 color indexed PCX file directly into video RAM
}

interface

CONST LINE_WIDTH = 320;

{Loads PCX file into buffer}
function LoadPCX(X, Y, WIDTH, HEIGHT: Word; ImageNumber: Word; SVGAMode: boolean): boolean;
{This function really copies the buffer into the screen if option = 0, and clears the are otherwise}
procedure DisplayPCX(option: Byte; SVGAMode: boolean);

implementation

uses utils, log,readbuff, ibmpc, vesa; 

type TScreenBuffer = array[0..63999] of Byte;

var ScreenBuffer:  ^TScreenBuffer;
    LatestPCXFileSize : Longint;
    LatestPCXX, LatestPCXY : Word;
    LatestPCXHeight, LatestPCXWidth :Word;
    PaletteBuffer :  array[0..767] of Byte;

      

procedure SetVGAPalette(var Palette); assembler;
asm
 LES DX, [Palette]
 XOR BX, BX
 MOV CX, 256
 MOV AX, 1012h
 INT 10h
end; 


function LoadPCX(X, Y, WIDTH, HEIGHT: Word; ImageNumber: Word; SVGAMode: boolean): boolean;
var Aux : Byte;
    AuxWord : Word;
    ImgWidth, ImgHeight : Word;
    CurrentPtr : Word;
    Color, Reps : Byte;
    CurrentX, CurrentY : Word;
    LastX, LastY : Word;
    ImageFileName : String;
    i, j: word;
    Success : boolean;
    
begin
 
 if (ImageNumber = 65535) then 
 begin
  ImageFileName := 'DAAD';
  width := 320;
  height := 200;
  if (SVGAMode) then
  begin
    width := 640;
    height := 400;
  end;
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
 FillChar(ScreenBuffer^, Sizeof(TScreenBuffer), 0);

  
 { Get the real dimension of the file}{Keep this strange order in this calculation, it's made to read file faster}
 ImgWidth := - (readbuff.fileGetByte(4) + 256 * readbuff.fileGetByte(5))  
                + readbuff.fileGetByte(8) + 256 * readbuff.fileGetByte(9) 
                + 1;
 ImgHeight := readbuff.fileGetByte(10) + 256 * readbuff.fileGetByte(11) 
               - (readbuff.fileGetByte(6) + 256 * readbuff.fileGetByte(7)+ 1);

 LastX := X + ImgWidth - 1;
 LastY := Y + ImgHeight - 1;
 if  Y + Height - 1 < LastY then LastY := Y + Height - 1; {Not higher than window}
 
 { Fix VGA Palette. It' a 18 bit DAC, 6+6+6 and PCX format saves each 6 bits in 
   a byte, but aligned to the most significative bit}
 for AuxWord := 0 to 767 do PaletteBuffer[AuxWord] := readbuff.fileGetByte(readbuff.bufferFileSize - 768 + AuxWord) SHR 2;


 { Load the pixels}
 CurrentX := X;
 CurrentY := Y;
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
   {Now we paint each pixel only if it fits within the window, otherwise, just skip}
   if (CurrentX -  X  < width) then
     ScreenBuffer^[LINE_WIDTH * CurrentY + CurrentX] := Color;
   Inc(CurrentX); {CurrentX := CurrentX + 1;}
   if (CurrentX  > LastX) then
   begin
    CurrentX := X;
    Inc(CurrentY); {CurrentY := CurrentY + 1;}
   end;
  end;  
 until (CurrentY  > LastY);

 LatestPCXFileSize := readbuff.bufferFileSize;
 LatestPCXX := X;
 LatestPCXY := Y;
 LatestPCXHeight := Height;
 LatestPCXWidth := Width;
 LoadPCX := true;
end;


procedure DisplayPCX(option: Byte; SVGAMode: boolean);
var i, offset : Word;
begin
 if (option=0) then
 begin

  if (LatestPCXFileSize <> 0) then
  begin
    {Now we really paint the picture}
    WaitVRetrace;
    {Set palette}
    SetVGAPalette(PaletteBuffer);
    { Copy from doble buffer}
    if (SVGAMode) then
    begin
      for i:= 0 to LatestPCXHeight - 1 do
      begin
          VESAPutImage(LatestPCXX, LatestPCXY + i, LatestPCXWidth, 1, ScreenBuffer^[i*LatestPCXWidth],0)
      end;
    end
    else
    begin
      offset := LINE_WIDTH * LatestPCXY + LatestPCXX;
      for i:= 0 to LatestPCXHeight - 1 do
      begin
          Move(ScreenBuffer^[offset], Mem[$A000:offset], LatestPCXWidth);
          Inc(offset,LINE_WIDTH);
      end;
    end; 
   end 
 end
 else (* option <> 0 *)
 begin
    ClearWindow(LatestPCXX, LatestPCXY, LatestPCXWidth, LatestPCXHeight, Windows[ActiveWindow].PAPER);
 end;
 
end;

begin
 GetMem(ScreenBuffer, Sizeof(TScreenBuffer));
 LatestPCXFileSize :=0;
end.
