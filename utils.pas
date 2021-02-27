{$I SETTINGS.INC}

(*
Several simple functions. Some of them are just wrappers of other functions but with more modern
pascal dialects names, in order to ease future portability
*)

unit utils;

interface


function inttostr(value: longint): string;
function intToHex(value:Word): String;
function strpad(str: string; filler: string; minLength:byte):string;
{Just as freepascal StringReplace, only if will enter and endless lookp if Origin is a substring of Dest}
function StringReplace(Str:String; Origin, Dest: String): String;
function StrUpper(Str: String) :String;
procedure Debug(Str: string);

implementation

uses dos, ibmpc;

function strpad(str: string; filler: string; minLength:byte):string;
begin
    while (length(str) < minLength) do str := filler + str;
    strpad := str;
end;

function inttostr(value: longint): string;
var aux: string;
begin
    Str(value, aux);
    inttostr := aux;
end;

function intToHex(value: word): String;
var  hexSym:String[16];
     tmp: String[5];
     hexDigitVal, hexLoc: byte;
begin
     hexSym := '0123456789ABCDEF';
     tmp := '$0000';   
     hexLoc := 5;  {do last digit, first}
     while value > 0 do
     begin
          hexDigitVal := value mod 16;
          tmp[hexLoc] := hexSym[hexDigitVal + 1];  {insert hex Sym}
          dec(hexLoc);  {move "left" to more significant hex digit}
          value := value div 16;   {remaining integer to convert}
     end;
     intToHex := tmp;
end;

function StringReplace(Str:String; Origin, Dest: String): String;
begin
    while (Pos(Origin, Str) <> 0) do
        Str := Copy(Str, 1, Pos(Origin, Str) - 1) + Dest + Copy(Str, Pos(Origin, Str) + length(Origin), 255);
    StringReplace := Str;
end;

function StrUpper(Str: String) :String;
var i : integer;
begin
 for i := 1 to Length(Str) do Str[i] := UpCase(Str[i]);
 StrUpper := Str;
end;

procedure Debug(Str: String);
begin
{$ifdef DEBUG}
    WriteLn(Str);
{$endif}
end;


end.