unit palette;

interface

procedure SetPalette(Color: Byte; R,G,B: Byte);
procedure SetAllPalette(var Palette);
procedure SetAllPaletteDirect;
procedure LoadPaletteFromFile(var F: File; FirstColor, Count: Word);

implementation

type TPalette = array[0..767] of Byte;
var currentPalette: ^TPalette;

procedure SetPalette(Color: Byte; R,G,B: Byte);
begin
    currentPalette^[Color*3] := R;
    currentPalette^[Color*3+1] := G;
    currentPalette^[Color*3+2] := B;
    SetAllPalette(currentPalette);
end;

procedure LoadPaletteFromFile(var F: File; FirstColor, Count: Word);
begin
    BlockRead(F, currentPalette^[FirstColor*3], Count*3);
end;



procedure SetAllPalette(var Palette);
begin
 move(Palette, currentPalette^, 768);
 asm
    LES DX, [Palette]
    XOR BX, BX
    MOV CX, 256
    MOV AX, 1012h
    INT 10h
 end;   
end; 

procedure SetAllPaletteDirect;
begin
 SetAllPalette(currentPalette^);
end;

begin
    GetMem(currentPalette, 768);
end.