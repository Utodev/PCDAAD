(*
Several simple functions. Some of them are just wrappers of other functions but with more modern
pascal dialects names, in order to ease future portability
*)

unit utils;

interface

function inttostr(value: longint): string;
function strpad(str: string; filler: string; minLength:byte):string;

implementation

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


end.