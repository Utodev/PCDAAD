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

uses utils, log, ibmpc; 

type TFileBuffer = array[0..65534] of Byte;
     TScreenBuffer = array[0..63999] of Byte;

var ScreenBuffer: ^TScreenBuffer;

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
    Buffer : ^TFileBuffer;
    Aux : Byte;
    AuxWord : Word;
    PCXFileSize : Longint;
    ImgWidth, ImgHeight : Word;
    CurrentPtr : Word;
    Color, Reps : Byte;
    CurrentX, CurrentY : Word;
    LastX, LastY : Word;
    ImageFileName : String;
    i, j: word;

begin
 if (ImageNumber = 65535) then ImageFileName := 'DAAD'
 else
 begin
  ImageFileName := IntToStr(ImageNumber);
  while (length(ImageFileName)<3) do ImageFileName := '0' + ImageFileName;
 end; 
 
 
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
  FreeMem(Buffer,PCXFileSize);
  exit;
 end; 

 { Get the real dimension of the file}
 ImgWidth := Buffer^[8] + 256 * Buffer^[9]  - (Buffer^[4] + 256 *Buffer^[5]) + 1;
 ImgHeight := Buffer^[10] + 256 * Buffer^[11] - (Buffer^[6] + 256 * Buffer^[7]+ 1);
 LastX := X + ImgWidth - 1;
 LastY := Y + ImgHeight - 1;
 if  Y + Height - 1 < LastY then LastY := Y + Height - 1; {Not higher than window}
 
 { Fix VGA Palette. It' a 18 bit DAC, 6+6+6 and PCX format saves each 6 bits in 
   a byte, but aligned to the most significative bit}
 for AuxWord := 0 to 767 do Buffer^[PCXFileSize-768+AuxWord] := Buffer^[PCXFileSize-768+AuxWord] SHR 2;


 { Load the pixels}
 CurrentX := X;
 CurrentY := Y;
 CurrentPtr := 128;
 repeat
  
  Color := Buffer^[CurrentPtr];
  if (Color AND $C0) = $C0 then       { If color > 192 it's not a color but a rep count }
  begin
   Reps := Color AND $3F;
   Inc(CurrentPtr); {CurrentPtr := CurrentPtr + 1;}
   Color := Buffer^[CurrentPtr];
  end
  else Reps := 1;
  Inc(CurrentPtr); {CurrentPtr := CurrentPtr + 1;}
  while  Reps>0 do
  begin
   Dec(Reps); {Reps := Reps -1;}
   {Now we paint each pixel only if it fits within the window, otherwise, just skip}
   if (CurrentX -  X  < width) then
     ScreenBuffer^[320 * CurrentY + CurrentX] := Color;
   Inc(CurrentX); {CurrentX := CurrentX + 1;}
   if (CurrentX  > LastX) then
   begin
    CurrentX := X;
    Inc(CurrentY); {CurrentY := CurrentY + 1;}
   end;
  end;  
 until (CurrentY  > LastY);
 Close(FPCXFile);
 FreeMem(Buffer,PCXFileSize);
 LoadPCX := true;

 {Now we really paint the picture}
 WaitVRetrace;
 { The palette is located at the last 768 bytes in the file}
 SetVGAPalette(Buffer^[PCXFileSize - 768]);
 { Copy from doble buffer}
 for i:= Y to LastY do 
 begin
    j := 320 * i + x;
    Move(ScreenBuffer^[j], Mem[$A000:j], ImgWidth);
 end;
 

end;


begin
 GetMem(ScreenBuffer, Sizeof(TScreenBuffer));
end.
