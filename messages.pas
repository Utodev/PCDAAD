{$I SETTINGS.INC}
unit messages;


interface

uses strings, global;

const MAX_MESSAGE_LENGTH = 8192;
      ESCAPE_OBJNAME = '_';

function getPcharMessage(TableOffset: Word; messageNumber : TFlagType): PChar;


implementation

uses ddb, tokens, flags;

var LongMessage : array [0..MAX_MESSAGE_LENGTH-1] of char;
    ObjMessage : array [0..512] of char;

procedure ReplaceArticles;
var i : word;
begin
 {$ifdef SPANISH}
 {un -> el}
 if (Upcase(ObjMessage[0]) = 'U') and (ObjMessage[1] = 'n') and (ObjMessage[2]=' ') then
 begin
  ObjMessage[0] := 'e';
  ObjMessage[1] := 'l';
  exit;
 end;
 
 {una, unos, unas --> la, los, las}
 if (Upcase(ObjMessage[0]) = 'U') and (ObjMessage[1] = 'n') then
 begin
  ObjMessage[0] := 'l';
  for i := 1 to StrLen(ObjMessage) do ObjMessage[i] := ObjMessage[i+1];
  exit;
 end;
 {$else}

 {a -> the}
 if (Upcase(ObjMessage[0]) = 'A') and (ObjMessage[1] = ' ') then
 begin
  ObjMessage[0] := 't';
  for i := StrLen(ObjMessage) downto 1 do ObjMessage[i+2] := ObjMessage[i];
  ObjMessage[1] := 'h';
  ObjMessage[2] := 'e';
  exit;
 end;
 

 {some -> the}
 if (Upcase(ObjMessage[0]) = 'S') and (ObjMessage[1] = 'o') and (ObjMessage[2] = 'm') 
     and (ObjMessage[3] = 'e') and (ObjMessage[4] = ' ') then
 begin
  for i := 2 to StrLen(ObjMessage) do ObjMessage[i] := ObjMessage[i+1];
  ObjMessage[0] := 't';
  ObjMessage[1] := 'h';
  exit;
 end;
  {$endif}
end;


function getPcharMessageInternal(TableOffset: Word; messageNumber : TFlagType; var WorkStr: array of char): PChar;
var Ptr : Word;
    i, j: Word;
    AByte : Byte;
    Token : String;
    TokenID : byte;
    EscapeText : PChar;
    
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
         WorkStr[i] := Token[j];
         i := i + 1;
        end; 
      end
      else 
      begin
        WorkStr[i] := chr(AByte xor OFUSCATE_VALUE);
        if (WorkStr[i] = ESCAPE_OBJNAME) then 
        begin
         EscapeText := getPcharMessageInternal(DDBHeader.objectPos, getFlag(FREFOBJ), ObjMessage);
         ReplaceArticles;
         for j:=0 to StrLen(EscapeText) - 1 do WorkStr[i+j] := EscapeText[j];
         i := i + StrLen(EscapeText);
        end 
        else i := i + 1;
      end;  
      Ptr := Ptr + 1;
      AByte := GetByte(Ptr);
    end; 
    WorkStr[i] := chr(0);

    getPcharMessageInternal := @WorkStr;
end;

function getPcharMessage(TableOffset: Word; messageNumber : TFlagType): PChar;
begin
 getPcharMessage := getPcharMessageInternal(TableOffset, messageNumber, LongMessage);
end;


end.