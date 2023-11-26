{$I SETTINGS.INC}
unit messages;


interface

uses strings, global;

const MAX_MESSAGE_LENGTH = 8192;
      ESCAPE_OBJNAME = '_';
      ESCAPE_OBJNAME_CAPS = '@';

function getPcharMessage(TableOffset: Word; messageNumber : TFlagType): PChar;
function getPCharMessageOTX(objno: TFlagType; Replace: boolean; Caps: boolean; StopAtDot : boolean): PChar;

implementation

uses ddb, tokens, flags;

var LongMessage : array [0..MAX_MESSAGE_LENGTH-1] of char;
    ObjMessage : array [0..512] of char;

(* 
   Replace:  whether to replace articles/pronouns or leave them like that
   Caps: if replace, wheter to use uppercase
   StopAtDot: Whether to stop message text at first dot or not
*)
procedure ReplaceArticles(Replace: Boolean; Caps: Boolean; StopAtDot:boolean); 
var i,j : word;
begin

 if (Replace or StopAtDot) then { when any of these options is ON, we also have to remove leading spaces}
  while (ObjMessage[0]=' ') do Move(ObjMessage[1], ObjMessage[0], Sizeof(ObjMessage)-1);

 if (StopAtDot) then
 begin
    i:=0;
    while ((ObjMessage[i]<>'.') and (ObjMessage[i]<>#0)) do i := i + 1;
    if (ObjMessage[i]='.') then ObjMessage[i]:=#0;
 end; 

 if (Replace) then
 begin
    if IsSpanish then
    begin
      {un -> el}
      if (Upcase(ObjMessage[0]) = 'U') and (Upcase(ObjMessage[1]) = 'N') and (ObjMessage[2]=' ') then
      begin
        IF Caps then ObjMessage[0] := 'E' else ObjMessage[0] := 'e';
        ObjMessage[1] := 'l';
        exit;
      end;
      
      {una, unos, unas --> la, los, las}
      if (Upcase(ObjMessage[0]) = 'U') and (Upcase(ObjMessage[1]) = 'N') then
      begin
        if Caps then ObjMessage[0] := 'L' else ObjMessage[0] := 'l';
        for i := 1 to StrLen(ObjMessage) do ObjMessage[i] := ObjMessage[i+1];
        exit;
      end;
    end
    else
    begin
      {In English, we have to remove the first word, whatever it is (if there are at least two words)}
      i := 0;
      while (ObjMessage[i] <> ' ') and (ObjMessage[i] <> #0) do i := i + 1;
      if (ObjMessage[i] = ' ') then
      begin
        for j := 0 to StrLen(ObjMessage)-i do ObjMessage[j] := ObjMessage[j+i];
      end;
    end;
 end; 
end;


function getPcharMessageInternal(TableOffset: Word; messageNumber : TFlagType; var WorkStr: array of char): PChar;
var Ptr : Word;
    i, j: Word;
    AByte : Byte;
    Token : String;
    TokenID : byte;
    EscapeText : PChar;
    PreviousWasCR : boolean;
    
begin
    Ptr := getWord(TableOffset + 2 * messageNumber);
    PreviousWasCR:= false;
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
        if (WorkStr[i] = ESCAPE_OBJNAME) OR ((WorkStr[i] = ESCAPE_OBJNAME_CAPS) and IsSpanish) then 
        begin
         EscapeText := getPcharMessageOTX(getFlag(FREFOBJ), true, WorkStr[i] = ESCAPE_OBJNAME_CAPS, true);
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

function getPCharMessageOTX(objno: TFlagType; Replace: boolean; Caps: boolean; StopAtDot : boolean): PChar;
var EscapeText : PChar;
begin
 EscapeText := getPcharMessageInternal(DDBHeader.objectPos, objno, ObjMessage);
 ReplaceArticles(Replace, Caps, StopAtDot);
 getPCharMessageOTX := EscapeText;
end;


end.