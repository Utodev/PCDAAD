{$I SETTINGS.INC}
unit messages;


interface

uses strings, global;

function getPcharMessage(TableOffset: Word; messageNumber : TFlagType): PChar;

implementation

uses ddb;

function getPcharMessage(TableOffset: Word; messageNumber : TFlagType): PChar;
begin
    (*FALTA*)   
end;

end.