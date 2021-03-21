program PCXFixer;

{Important: please notice unlike the DAAD interpreter, this tool is to be compiled with Free pascal.}
{ It's a tool for modern OS like Windows, MacOS or Linux}
{$MODE OBJFPC}
{$I-}

 uses sysutils;

type FileBuffer = array[0..65534] of Byte;

var InFileName, OutFileName : String;
    InFile, OutFile : File;
    PR, PG, PB: Byte;
    IR, IG, IB: Byte;
    Buffer : ^FileBuffer;
    BufferSize : Longint;
    UsedColors: array[byte] of word;
    i : integer;
    CurrentPtr :  Word;
    Color, Reps: Byte;
    ColorPaper, ColorInk: Word;



procedure Syntax;
begin
    WriteLn('PSXFIXER fixes PCX files so color 0 and 15 have the RGB components selected.');
    WriteLn('Syntax: ');
    WriteLn('PCXFIXER <InFile> <OutFile> [<PAPER R> <PAPER G> <PAPER B> <INK R> <INK G> <INK B>]');
    WriteLn('If RGB component values are missing, it will default to pure black (paper) and pure');
    WriteLn('white (ink). Please notice the VGA palette has 6 bits per component, so maximum value');
    WriteLn('for a component is 63.');
    Halt(0);
end;

procedure Error(Str: String);
begin
 Write('Error: ');
 Write(Str);
 WriteLn('.');
 Halt(1);
end; 

(* MAIN *)
begin
  if ParamCount < 2 then Syntax;
  if (ParamCount > 2) and (ParamCount <> 8) then Syntax;
  InFileName := ParamStr(1);
  OutFileName := ParamStr(2);
  if ParamCount > 2 then
  begin
   try
    PR := StrToInt(ParamStr(3));
    PG := StrToInt(ParamStr(4));
    PB := StrToInt(ParamStr(5));
    IR := StrToInt(ParamStr(6));
    IG := StrToInt(ParamStr(7));
    IB := StrToInt(ParamStr(8));
   except
    Error('Invalid RGB component, it must be in the 0-63 range');
   end; 
  end
  else
  begin
   PR := 0;
   PG := 0;
   PB := 0;
   IR := 63;   
   IG := 63;
   IB := 63;
  end;
  if (IR>$3F) or (IG>$3F)  or (IB>$3F) or (PR>$3F) or (PG>$3F) or (PB>$3F) then Error('Max value for RGB components is 63');
  IF (NOT FileExists(InFileName)) then Error('Input file not found');

  Assign(InFile, InFileName);
  Reset(InFile, 1);
  BufferSize := filesize(InFile);
  if BufferSize>65535 then Error('File too big, maximum is 65535 bytes.');
  GetMem(Buffer, BufferSize);
  BlockRead(InFile, Buffer^, BufferSize);
  Close(InFile);

  (* Now let's do magic *)
  WriteLn('Looking for less used colors...');
  for  i:= 0 to 255 do UsedColors[i]:=0;
  CurrentPtr := 128;
  while CurrentPtr<BufferSize - 769 do
  begin
    Color := Buffer^[CurrentPtr];
    if (Color<=192) then reps := 1
    else
    begin
     Reps := Reps AND $3F;
     CurrentPtr := CurrentPtr + 1;
     Color := Buffer^[CurrentPtr];
    end;
    UsedColors[Color] := UsedColors[Color] + Reps;
    CurrentPtr := CurrentPtr + 1; 
  end;

  WriteLn('Determining best colors to be replaced');
  { Now I have a list of colors and how many times they were used,
    let's look for not used colors in the 0-191 range, to avoid
    modfying the compression}
  ColorPaper := 256;
  ColorInk := 256;
  i := 0 ;
  while (i<192) and ((ColorPaper=256) or (ColorInk=256)) do
  begin
   if (UsedColors[i]=0) then
   begin
    if ColorPaper = 256 then ColorPaper :=i 
                        else ColorInk := i;
   end;
   i := i + 1;
  end;


  if (ColorPaper=256) or (ColorInk=256) then Error('No colors available for switching');

  WriteLn('PAPER will be replaced with color ', ColorPaper);
  WriteLn('INK will be replaced with color ', ColorInk);
  WriteLn('Replacing....');
  CurrentPtr := 128;
  while CurrentPtr<BufferSize - 769 do
  begin
    Color := Buffer^[CurrentPtr];
    if (Color<=192) then reps := 1
    else
    begin
     Reps := Reps AND $3F;
     CurrentPtr := CurrentPtr + 1;
     Color := Buffer^[CurrentPtr];
    end;
    if (Color = 0) then Buffer^[CurrentPtr] := ColorPaper;
    if (Color = 15) then Buffer^[CurrentPtr] := ColorInk;
    
    CurrentPtr := CurrentPtr + 1; 
  end;

 WriteLn('Updating palette.');
 {Update the Palette -  First copy the palette at color 0 to where ColorPaper is}   
 Buffer^[BufferSize-768 + ColorPaper * 3] := Buffer^[BufferSize-768];
 Buffer^[BufferSize-768 + ColorPaper * 3 + 1] := Buffer^[BufferSize-768 + 1];
 Buffer^[BufferSize-768 + ColorPaper * 3 + 2] := Buffer^[BufferSize-768 + 2];
 {Now copy the palette at color 15 to where ColorInk is}   
 Buffer^[BufferSize-768 + ColorInk * 3] := Buffer^[BufferSize-768 + 15 * 3];
 Buffer^[BufferSize-768 + ColorInk * 3 + 1] := Buffer^[BufferSize-768 + 15* 3 +1];
 Buffer^[BufferSize-768 + ColorInk * 3 + 2] := Buffer^[BufferSize-768 + 15*3 + 2];
 {Now set color 0}
 Buffer^[BufferSize-768] := PR SHL 2;
 Buffer^[BufferSize-768+1] := PG SHL 2;
 Buffer^[BufferSize-768+2] := PB SHL 2;
 {Now set color 15}
 Buffer^[BufferSize-768+15*3] := IR SHL 2;
 Buffer^[BufferSize-768+15*3+1] := IG SHL 2;
 Buffer^[BufferSize-768+15*3+2] := IB SHL 2;
 
 WriteLn('Done.');

 Assign(OutFile, OutFileName);
 Rewrite(OutFile,1);
 if (ioresult<>0) then Error('Invalid output file');
 Blockwrite(OutFile, Buffer^, BufferSize);
 Close(Outfile);
end.