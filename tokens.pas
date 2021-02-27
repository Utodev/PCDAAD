unit tokens;

interface

function getToken(id: word): String;

implementation

uses ddb, utils;



function getToken(id: word): String;
var Ptr : Word;
    Index : Word;
    AuxStr : String;
begin
    Index := 0;
    Ptr := DDBHeader.tokenPos + 2; {Apparently, token table starts one byte after the token pointer}
    while (Index < id) do
    begin
     if GetByte(Ptr) > 127 then Index := Index + 1;
     Ptr := Ptr + 1;
    end;
   
    AuxStr := '';
    while (GetByte(Ptr) <= 127) do
    begin
        AuxStr := AuxStr + chr(GetByte(Ptr));
        Ptr := Ptr + 1;
    end;
    AuxStr := AuxStr + chr(GetByte(Ptr) and 127);
    while (Pos('_',AuxStr)>0) do AuxStr := StringReplace(AuxStr, '_', ' ');
    getToken := AuxStr;
end;

end.