{$I SETTINGS.INC}
UNIT PCX;

{
    This unit is able to load a 256 color indexed PCX file directly into video RAM
}

interface

{ Defines the file name to load and the Window where to paint it. If the picture is smaller than the defined
  window it is painted anyway, if the picture is larger than the window, it's}
function LoadPCX(X, Y, WIDTH, HEIGHT: Word; ImageNumber: Word): boolean;

implementation

uses utils, log; 

type FileBuffer = array[0..65534] of Byte;

(*FALTA HACER ESTO COMPATIBLE CON 8086 , PORQUE $G+ es 286 *)

procedure SetVGAPalette(var Palette); assembler;
asm
 LES DX, [Palette]
 XOR BX, BX
 MOV CX, 256
 MOV AX, 1012h
 INT 10h
end; 


function LoadPCX(X, Y, WIDTH, HEIGHT: Word; ImageNumber: Word): boolean;
var FPCXFile : file;
    Buffer : ^FileBuffer;
    Aux : Byte;
    AuxWord : Word;
    PCXFileSize : Longint;
    ImgWidth, ImgHeight : Word;
    CurrentPtr : Word;
    Color, Reps : Byte;
    CurrentX, CurrentY : Word;
    LastX, LastY : Word;
    ImageFileName : String;

begin
 ImageFileName := IntToStr(ImageNumber);
 while (length(ImageFileName)<3) do ImageFileName := '0' + ImageFileName;
 
 Assign(FPCXFile, ImageFileName + '.vga');
 Reset(FPCXFile, 1);
 if (ioresult <> 0) then
 begin
  Assign(FPCXFile, ImageFileName + '.pcx');
  Reset(FPCXFile, 1);
  if (ioresult <> 0) then
  begin
   LoadPCX := false;
   exit;
  end; 
 end; 

 PCXFileSize := FileSize(FPCXFile);
 if (PCXFileSize>65535) then 
 begin
  LoadPCX := false;
  exit;
 end; 


 GetMem(Buffer,PCXFileSize);
 BlockRead(FPCXFile, Buffer^, PCXFileSize);

 Aux := Buffer^[PCXFileSize - 769];
 if (Aux <> $0C) then  {Mark of 256 color palette}
 begin
  LoadPCX := false;
  exit;
 end; 

 { Get the real dimension of the file}
 ImgWidth := Word(Buffer^[8]) - Word (Buffer^[4]);
 ImgHeight := Word(Buffer^[10]) - Word(Buffer^[6]);
 LastX := X + ImgWidth ;
 LastY := Y + ImgHeight;

 
 { Fix VGA Palette. It' a 18 bit DAC, 6+6+6 and PCX format saves each 6 bits in 
   a byte, but aligned to the most significative bit}
 for AuxWord := 0 to 767 do Buffer^[PCXFileSize-768+AuxWord] := Buffer^[PCXFileSize-768+AuxWord] SHR 2;

 { The palette is located at the last 768 bytes in the file}
 SetVGAPalette(Buffer^[PCXFileSize - 768]);

 { Load the pixels}
 CurrentX := X;
 CurrentY := Y;
 CurrentPtr := 128;
 repeat
  
  Color := Buffer^[CurrentPtr];
  if Color > 192 then       { If color > 192 it's not a color but a rep count }
  begin
   Reps := Color - 192;
   CurrentPtr := CurrentPtr + 1;
   Color := Buffer^[CurrentPtr];
  end
  else Reps := 1;
  CurrentPtr := CurrentPtr + 1;
  while  Reps>0 do
  begin
   Dec(Reps);
   {Now we paint each pixel only if it fits within the window, otherwise, just skip}
   if (CurrentX -  X  < width) and (CurrentY - Y < height ) then
     Mem[$A000: 320 * CurrentY + CurrentX] := Color;
   Inc(CurrentX);
   if (CurrentX  > LastX) then
   begin
    CurrentX := X;
    Inc(CurrentY);
   end;
  end;
 until (CurrentY  > LastY);
 Close(FPCXFile);
 LoadPCX := true;
end;


end.
