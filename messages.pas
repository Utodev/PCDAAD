{$I SETTINGS.INC}
unit messages;


interface

uses strings, global;

const MAX_MESSAGE_LENGTH = 8192;

function getPcharMessage(TableOffset: Word; messageNumber : TFlagType): PChar;

implementation

uses ddb, tokens;

var LongMessage : array [0..MAX_MESSAGE_LENGTH-1] of char;

function getPcharMessage(TableOffset: Word; messageNumber : TFlagType): PChar;
var Ptr : Word;
    i, j: Word;
    AByte : Byte;
    Token : String;
    TokenID : byte;
begin
    Ptr := getWord(TableOffset + 2 * messageNumber);
    i := 0;
    AByte := GetByte(Ptr);
    while (AByte <> ($0A xor OFUSCATE_VALUE)) and ( i < MAX_MESSAGE_LENGTH) do 
    begin
     if (AByte < 128) then
      begin
       TokenID := (AByte XOR OFUSCATE_VALUE) - 128;
       Token := getToken(TokenID);
        for j := 1 to Length(Token) do
        begin
         LongMessage[i] := Token[j];
         i := i + 1;
        end; 
      end
      else 
      begin
        LongMessage[i] := chr(AByte xor OFUSCATE_VALUE);
        i := i + 1;
      end;  
      Ptr := Ptr + 1;
      AByte := GetByte(Ptr);
    end; 
    LongMessage[i] := chr(0);
    getPcharMessage := LongMessage;
end;

end.