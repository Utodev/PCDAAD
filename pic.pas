{$I SETTINGS.INC}

UNIT PIC;

{
    This unit was originaly able to load a 256 color indexed PCX file directly into video RAM. Now it also can
    load MSD files, an internal format that reduces size and provides some original DAAD featuras, as fixed images
    and limited palette update.

    Fixed images are those that are always shown at a fixed position, ignoring the current window. Floating images
    are those that are shown at the current window position, and are limited to the current window size. In DAAD
    fixed images didn't apply palette at all, while floating images could have a limited pallete applied. In this
    implementation, both fixed an float images can limit palette.
}

interface

var DoubleBuffer: boolean; { If true, the double buffer feature is activated.}
var GraphicsToScreen: boolean; { If true, the graphics buffer is written to the screen, otherwise to the buffer}


{Loads pciture file into buffer}
function LoadPicture( ImageNumber: Word; SVGAMode: boolean): boolean;
{This function really copies the buffer into the screen if option = 0, and clears the are otherwise}
procedure DisplayPicture(option: Byte; SVGAMode: boolean);
{This function initalizes the sceen Buffers}
procedure InitializePictures(SVGAMode: boolean);
{This function clears the picture system}
procedure ClearPictures;

{These are the implmentation of all the GFX functions}
procedure DBBuffertoScreen; {Copy the buffer to the screen}
procedure DBScreentoBuffer; {Copy the screen to the buffer}
procedure DBSwapBuffers; {Swap the buffers}
procedure DBGraphicsWriteToScreen; {Write the graphics buffer to the screen}
procedure DBGraphicsWriteToBuffer; {Write the graphics buffer to the buffer}
procedure DBClearScreen; {Clear the screen}
procedure DBClearBuffer; {Clear the buffer}
procedure DBSetPalette(BaseFlag:byte); {Set the palette}
procedure DBgetPalette(BaseFlag:byte); {Get the palette}


implementation

uses utils, log,readbuff, ibmpc, vesa, palette, flags; 

type TScreenBuffer = array[0..63999] of Byte;

type TImageType = (imageTypePCX, imageTypeMSD);

var ScreenBuffer: array [0..3] of ^TScreenBuffer;
var DoubleBufferMem: ^TScreenBuffer;
    NumBuffers: byte;
    latestPictureFileSize : Longint;
    latestPictureHeight, latestPictureWidth :Word;  { The dimensions of the image currently in the screenbuffer}
    PaletteBuffer :  array[0..767] of Byte; 
    imageType: TImageType; { type of image currently loaded PCX or MSD}
    scanlineWidth : Word;  { Width of each scanline in current mode. Not related to the image but to the screen}
    scanlineNumber : Word; { Number of scanlines in current mode. Not related to the image but to the screen}
    isFloat : boolean; { Determines if the picture loaded is float. If not, then is fixed and fixedX and fixedY are used}
    fixedX, fixedY : Word; { Fixed position: if fixed, the image is shown at that position and ignores window 
                           limits, if float, it's shown at the current window and applies window limits}
    Palette0, Palette1 : Byte; { The image pallete will only be updated from color Palette0 to color Palette1, 
                                if Palette0>Palette1 then the palette is not updated at all}
    


function loadMSD: boolean;forward;
function loadPCX: boolean;forward;



{ This function initializes the screen buffer. The number of buffers is determined by the mode, and the
  size of each buffer is determined by the scanlineWidth and scanlineNumber variables.}
procedure InitializePictures(SVGAMode: boolean);
var i : byte;
begin
 if (SVGAMode) then NumBuffers := 4 else NumBuffers := 1;
 if (SVGAMode) then scanlineWidth := 640 else scanlineWidth := 320;
 if (SVGAMode) then scanlineNumber := 400 else scanlineNumber := 200;
 for i:=0 to NumBuffers-1 do GetMem(ScreenBuffer[i], Sizeof(TScreenBuffer));
 if (DoubleBuffer) then GetMem(DoubleBufferMem, Sizeof(TScreenBuffer));
end;      

procedure ClearPictures;
var i : byte;
begin
 for i:=0 to NumBuffers-1 do FreeMem(ScreenBuffer[i], Sizeof(TScreenBuffer))
end;




function LoadPicture(ImageNumber: Word; SVGAMode: boolean): boolean;
var ImageFileName : String;
    Success : boolean;
    
begin

  { Determine file name }
  if (ImageNumber = 65535) then ImageFileName := 'DAAD' else
  begin
    ImageFileName := IntToStr(ImageNumber);
    while (length(ImageFileName)<3) do ImageFileName := '0' + ImageFileName;
  end; 


  { First try to load .MSD file, internal, internal format able to do float/fixed, palette limits, etc.}
  imageType := imageTypePCX;
  Success := readbuff.fileopen(ImageFileName + '.MSD');
  if (Success) then imageType := imageTypeMSD
  else
  begin
    Success := readbuff.fileopen(ImageFileName + '.pcx'); { otherwise load .PCX file, always fixed at 0,0}
    if (not Success) then
    begin
      Success := readbuff.fileopen(ImageFileName + '.VGA');{otherwise .VGA, that is just a PCX file renamed as .VGA}
      if (not Success) then
      begin
        latestPictureFileSize := 0;
        LoadPicture := false;
        exit;
      end;
    end;
  end;  

  if ImageType = imageTypeMSD 
   then LoadPicture := loadMSD
   else LoadPicture := loadPCX;

end;


procedure DisplayPicture(option: Byte; SVGAMode: boolean);
var i, offset : Longint;
    DIVV : word;
    MODD: word;
    ApplyableHeight, ApplyableWidth : Word;     
    Divider : byte;
    x, y, width, height : Word;

begin     

x := Windows[ActiveWindow].col * 8;
y := Windows[ActiveWindow].line * 8;
width := Windows[ActiveWindow].width * 8;
height := Windows[ActiveWindow].height * 8;


{ In case the image in the buffer is fixed, we will set the current window to the dimensions of 
the Window from fixedX,fixedY with image width.}
if not isFloat then 
begin
  if SVGAMode then Divider := 2
              else Divider := 1;
  x := fixedX DIV Divider;
  y := fixedY DIV Divider;
  width := latestPictureWidth DIV Divider;
  height := latestPictureHeight DIV Divider;
end;

if (SVGAmode) then
begin
   width := width SHL 1;
   height := height SHL 1;
   X := X SHL 1;
   Y := Y SHL 1;
end;  

if verbose then TranscriptPas('DisplayPicture: ' + IntToStr(x) + ',' + IntToStr(y) + ' ' + 
IntToStr(width) + 'x' + IntToStr(height) + ' option=' + IntToStr(option) + #13);

 if (option=0) then
 begin
  if (latestPictureFileSize <> 0) then
  begin

    ApplyableHeight := min(height, latestPictureHeight);
    ApplyableWidth := min(width, latestPictureWidth);
    

    {Now we really paint the picture}
    WaitVRetrace;
    {Set palette}
    if (Palette0 <= Palette1) then SetPartialPalette(PaletteBuffer, Palette0, Palette1);
    { Copy from doble buffer}
    if (SVGAMode) then
    begin
      VESARectangle(X, Y, ApplyableWidth, ApplyableHeight, Windows[ActiveWindow].PAPER);
      for i:= 0 to ApplyableHeight - 1 do
      begin
          DIVV := (i*640) DIV Sizeof(TScreenBuffer); {calculate wich buffer}
          MODD := (i*640) MOD Sizeof(TScreenBuffer); {calculate wich offset}
          VESAPutImage(X, Y + i, ApplyableWidth, 1, ScreenBuffer[DIVV]^[MODD],0);
          if (ApplyableWidth < width) then 
           VESARectangle(X + ApplyableWidth, Y + i, width - ApplyableWidth, 1, Windows[ActiveWindow].PAPER);

      end;
    end
    else
    begin
      offset := 0;      
      for i:= 0 to ApplyableHeight - 1 do
      begin
          if (GraphicsToScreen) then
          begin
            Move(ScreenBuffer[0]^[offset], Mem[$A000:(Y+i)*scanlineWidth + X], ApplyableWidth);
            if (ApplyableWidth < width) then 
            FillChar(Mem[$A000:(Y+i)*scanlineWidth + X + ApplyableWidth], width - ApplyableWidth, Windows[ActiveWindow].PAPER);
          end
          else
          begin
            Move(ScreenBuffer[0]^[offset], Pointer(longint(DoubleBufferMem)  + (Y+i) * scanlineWidth + X)^, ApplyableWidth);
            if (ApplyableWidth < width) then 
              FillChar(Pointer(longint(DoubleBufferMem)  + (Y+i) * scanlineWidth + X + ApplyableWidth)^,
                 width - ApplyableWidth, Windows[ActiveWindow].PAPER);
          end;  
          Inc(offset,scanlineWidth);
      end;
    end; 
   end 
 end
 else { option <> 0 }
 begin
  if SVGAMode then ClearWindow(X SHR 1, Y  SHR 1, width SHR 1, height  SHR 1, Windows[ActiveWindow].PAPER)
            else ClearWindow(X, Y, width, height, Windows[ActiveWindow]   .PAPER); 
 end;
end;




{ Internal function that loads PCX file in the screen buffer. The uncompressed pixels go to ScreenBuffer,
 and the palette goes to PaletteBuffer files that come as PCX are always considered float images }
function loadPCX: boolean;
var Aux : Byte;
    AuxWord : Word;
    ImgHeight, ImgWidth : Word;
    CurrentPtr : Longint;
    Color, Reps : Byte;
    CurrentX, CurrentY : Longint;
    i : byte;
    DIVV : word;
    MODD: word;
begin

  Aux := readbuff.fileGetByte(readbuff.bufferFileSize - 769);
  
  if (Aux <> $0C) then  {Mark of 256 color palette}
  begin
    readbuff.fileclose;
    latestPictureFileSize := 0;
    loadPCX := false;
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
    latestPictureFileSize := 0;
    loadPCX := false;
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
      DIVV := (scanlineWidth * CurrentY + CurrentX) DIV Sizeof(TScreenBuffer);  {Calculate the buffer}
      MODD := (scanlineWidth * CurrentY + CurrentX) MOD Sizeof(TScreenBuffer); 
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
  latestPictureFileSize := readbuff.bufferFileSize;
  latestPictureHeight := ImgHeight;
  latestPictureWidth := ImgWidth;
  isFloat := true; { Images loaded as PCX are always floating images}
  Palette0 := 0; 
  Palette1 := 255; { The palette for PCX files is always fully updated}

  if verbose then TranscriptPas('PCX file loaded into screen buffer:: ' + IntToStr(latestPictureWidth) + 'x' +
     IntToStr(latestPictureHeight) +  ' Palette0=' + IntToStr(Palette0) + ' Palette1=' + 
     IntToStr(Palette1) + ' Floating image.'#13);

  loadPCX := true;
end;


{ This function loads the MSD file in the screen buffer. The uncompressed pixels go to ScreenBuffer,
 and the palette goes to PaletteBuffer. }
function loadMSD: boolean;
var FullImageSize : Longint;
    CurrentPtr : Longint;
    i, j: longint;  (* Keep these as longint our you would have problems with word*)
    Aux1, Aux2 : Byte;
    AuxWord : Word;
    DIVV : word;
    MODD: word;
    AuxBorrame: String;

begin
  
  
 {
    MSD format is made by SCRMAKER. It's a precooked format which allows functionalities 
    as fixed images or limited palette, unlike PCX. It has a header that is detailed at the end 
    of this file.
  }
  
    Aux1 := readbuff.fileGetByte(0);
    Aux2 := readbuff.fileGetByte(1);
    if (Aux1 <> $DA) OR (Aux2<> $AD) then { check for MSD signature}
    begin
      readbuff.fileclose;
      latestPictureFileSize := 0;
      loadMSD := false;
      exit;
    end;
    
    latestPictureFileSize := readbuff.bufferFileSize;
    latestPictureWidth := readbuff.fileGetWord(2);
    latestPictureHeight := readbuff.fileGetWord(4);
    Palette0 := readbuff.fileGetByte(6);
    Palette1 := readbuff.fileGetByte(7);
    fixedX := readbuff.fileGetWord(8);
    fixedY := readbuff.fileGetWord(10);
    isFloat := fixedY = 400;



    if verbose then 
    begin
        TranscriptPas('MSD file loaded into screen buffer: ' + IntToStr(latestPictureWidth) + 'x' + 
        IntToStr(latestPictureHeight) + ' Palette0=' + IntToStr(Palette0) + ' Palette1=' +
        IntToStr(Palette1));
        if isFloat then TranscriptPas(' Floating image'#13) 
                   else TranscriptPas(' fixedX=' + IntToStr(fixedX) + ' fixedY=' + IntToStr(fixedY) + #13);
    end;


    { The MSD format has a header of 16 bytes, then comes the palette (768 bytes), and then the pixels.}

    { Load the palette into the palettebuffer}
    for AuxWord := 0 to 767 do 
      PaletteBuffer[AuxWord] := readbuff.fileGetByte(16 +   AuxWord) SHR 2;
 
    { Load the pixels into the screen buffer}
    AuxBorrame := '';
    for i := 0 to latestPictureHeight -1 do
      for j := 0 to latestPictureWidth -1 do
      begin
        DIVV := (scanlineWidth * i + j) DIV Sizeof(TScreenBuffer); {calculate wich buffer}
        MODD := (scanlineWidth * i + j) MOD Sizeof(TScreenBuffer); 
        ScreenBuffer[DIVV]^[MODD] := readbuff.fileGetByte(16 + 768 + i * latestPictureWidth + j);
      end;
        

    readbuff.fileclose;
    loadMSD := true;
end;


procedure DBBuffertoScreen; {Copy the buffer to the screen}
begin
  if (DoubleBuffer) then
  begin
    Move(DoubleBufferMem^, Mem[$A000:0000], Sizeof(TScreenBuffer));
  end
end;

procedure DBScreentoBuffer; {Copy the screen to the buffer}
begin
  if (DoubleBuffer) then
  begin
    Move(Mem[$A000:0000], DoubleBufferMem^, Sizeof(TScreenBuffer));
  end
end;

procedure DBSwapBuffers; {Swap the buffers}
var Temp: ^TScreenBuffer;
begin
  if (DoubleBuffer) then
  begin
   GetMem(Temp, Sizeof(TScreenBuffer));
   Move(DoubleBufferMem^, Temp^, Sizeof(TScreenBuffer));
   Move(Mem[$A000:0000], DoubleBufferMem^, Sizeof(TScreenBuffer));
   Move(Temp^, Mem[$A000:0000], Sizeof(TScreenBuffer));
   FreeMem(Temp, Sizeof(TScreenBuffer));
  end;
end;

procedure DBGraphicsWriteToScreen; {Write the graphics buffer to the screen}
begin
   GraphicsToScreen := true;
end;

procedure DBGraphicsWriteToBuffer; {Write the graphics buffer to the buffer}
begin
   if DoubleBuffer then GraphicsToScreen := false;
end;

procedure DBClearScreen; {Clear the screen}
begin
  FillChar(Mem[$A000:0000], Sizeof(TScreenBuffer), Windows[ActiveWindow].PAPER);
end;

procedure DBClearBuffer; {Clear the buffer}
begin
  if (DoubleBuffer) then FillChar(DoubleBufferMem^, Sizeof(TScreenBuffer), Windows[ActiveWindow].PAPER);
end;


procedure DBSetPalette(BaseFlag: Byte); {Set the palette}
begin
 SetPalette(getFlag(BaseFlag), getFlag(BaseFlag + 1) SHR 2, 
    getFlag(BaseFlag + 2)  SHR 2, getFlag(BaseFlag + 3)  SHR 2);           
end;


procedure DBgetPalette(BaseFlag: Byte); {Get the palette}
var R, G, B: Byte;
begin
  getPalette(getFlag(BaseFlag), R, G, B);
  setFlag(BaseFlag + 1, R SHL 2);
  setFlag(BaseFlag + 2, G SHL 2);
  setFlag(BaseFlag + 3, B SHL 2);
end;

begin
 latestPictureFileSize :=0;
 DoubleBuffer := false; 
 GraphicsToScreen := true; 
end.

{
    The MSD files have  a 16 bit header like this:

    offset 0,1: 0xDAAD (MSD Signature)
		Offset 2, 3: width in pixels, big endian
		Offset 4, 5: height in pixels, big endian
		Offset 6: Palette limits, lower value
		Offset 7: Palette limits, upper value ; if upper<lower, no palette will be applied
		Offset 8,9: Fixed position, X, big endian
		Offset 10,11: Fixed position, Y (if Y=640, it's a floating image, not fixed), big endian
		Offset 12: flags (Bit 0=1, 1=RLE compressed)
		Offser 13-15 : reserved 
		Then comes 768 bytes for the palette (no matter the palette limits, the palette is always saved complete)
		Then comes the pixels data, using same encoding as PCX
}