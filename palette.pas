unit palette;

interface

procedure SetPalette(Color: Byte; R,G,B: Byte);
procedure SetAllPalette(var Palette: array of byte);
procedure SetPartialPalette(var Palette: array of byte; FirstColor,  LastColor : byte);
procedure SetAllPaletteDirect;
procedure LoadPaletteFromFile(var F: File; FirstColor, Count: Word);
procedure getPalette(Color: Byte; var R,G,B: Byte);

implementation

type TPalette = array[0..767] of Byte;
var currentPalette: ^TPalette;

procedure SetPalette(Color: Byte; R,G,B: Byte);
begin
    currentPalette^[Color*3] := R;
    currentPalette^[Color*3+1] := G;
    currentPalette^[Color*3+2] := B;
    SetAllPalette(currentPalette^);
end;

procedure LoadPaletteFromFile(var F: File; FirstColor, Count: Word);
begin
    BlockRead(F, currentPalette^[FirstColor*3], Count*3);
end;



procedure SetAllPalette(var Palette: array of byte);
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

procedure getPalette(Color: Byte; var R,G,B: Byte);
begin
    Port[$3c7] := Color;
    R := Port[$3c9];
    G := Port[$3c9];
    B := Port[$3c9];
end;



procedure SetPartialPalette(var Palette: array of byte; FirstColor,  LastColor : byte);
var i : byte;
begin
    for i := FirstColor to LastColor do
    begin
        currentPalette^[i*3] := Palette[i*3];
        currentPalette^[i*3+1] := Palette[i*3+1];
        currentPalette^[i*3+2] := Palette[i*3+2];
    end;
    SetAllPalette(currentPalette^);
end;

procedure SetAllPaletteDirect;
begin
 SetAllPalette(currentPalette^);
end;

begin
    GetMem(currentPalette, 768);
end.