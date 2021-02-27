{$I SETTINGS.INC}
unit parser;

interface
uses global;

const WORD_LENGHT = 5;
	  STANDARD_SEPARATORS : set of char = ['.',',',';',':','"',''''];
	  MAX_CONJUNCTIONS = 256;

type TWord = String[WORD_LENGHT];
type TVocType = (VOC_VERB,VOC_ADVERB,VOC_NOUN, VOC_ADJECT, VOC_PREPOSITION, VOC_CONJUGATION,  VOC_PRONOUN, VOC_ANY);
type TWordRecord = record
                    ACode: integer;
                    AType: TVocType;
                   end; 


{Returns the code for a specific word of a specific type, or any}
{type if AVocType= VOC_ANY. If not found returns TWordRecord.ACode = -1}
procedure FindWord(AWord: TWord; AVocType : TVocType; var Result: TWordRecord);

{Extract an order from inputBuffer of request an order if empty}
{Then parsers first order in the buffer and sets flags. Returns
{true if a valid LS is found (a verb at least)} 
function parse(Option:TFlagType):boolean;

{ Initializes the parser by reading conjunctions from the DDB}
procedure InitializeParser;

{Clears the inputBufffer}
procedure newtext;


implementation

uses ddb, flags, graph, errors, utils, messages;

var PreviousVerb: TFlagType;

{This array keeps the conjuctions provided by the DDB}
var Conjunctions : array [0..MAX_CONJUNCTIONS-1] of TWord;
	ConjunctionsCount : Byte;
   
{This string contains what has been received from the player input}   
{but when read, conjunctions are replaced with a dot to ease order}
{split later.}
    inputBuffer: String;

procedure newtext;
begin
 inputBuffer := '';
end;

procedure InitializeParser;
var i, ptr : Word;
	AVocWord : TWord;
begin
 Debug('Initializing parser');
 {Clears the input buffer}
 inputBuffer := '';
 { Creates the Conjunctions array}
 Ptr := DDBHeader.vocabularyPos;
  while (GetByte(Ptr)<> 0) do
  begin
   if TVocType(GetByte(Ptr+6)) = VOC_CONJUGATION then
	begin
	AVocWord := '';
		for i := 0 to WORD_LENGHT -1 do 
			if ((GetByte(Ptr+i) XOR OFUSCATE_VALUE)<>32) 
			then AVocWord := AVocWord + CHR(GetByte(Ptr+i) XOR OFUSCATE_VALUE); 
			{Conjunctions are saved with leading and trailing spaces because that}
			{way is how it should be found in player orders.}
			if (ConjunctionsCount =  MAX_CONJUNCTIONS) 
			  then Error(5,'Too many conjunctions. Maximum accepted is ' + inttostr(MAX_CONJUNCTIONS));
			Conjunctions[ConjunctionsCount] := ' ' + AVocWord + ' ';
			ConjunctionsCount := ConjunctionsCount + 1;
	end;
	Ptr := Ptr + 7; {point to next word}
  end; {While}
end;



procedure FindWord(AWord: TWord; AVocType : TVocType; var Result: TWordRecord);
var i, ptr : Word;
	AVocWord : TWord;
  AWordRecord : TWordRecord;
begin
 Ptr := DDBHeader.vocabularyPos;
 Result.ACode := -1;
 AWord := StrUpper(AWord);
 while (GetByte(Ptr)<> 0) do
 begin
 {Get a word from Vocabulary}
  AVocWord := '';
  for i := 0 to WORD_LENGHT -1 do 
    if ((GetByte(Ptr+i) XOR OFUSCATE_VALUE)<>32) 
      then AVocWord := AVocWord + CHR(GetByte(Ptr+i) XOR OFUSCATE_VALUE); 
 

  {If matches text and type, or type is VOC_ANY}
  if (Aword = AVocWord)  
   then if (AVocType = VOC_ANY) or (AVocType = TVocType(GetByte(Ptr+6)))  
    then begin
      Result.ACode := GetByte(Ptr+5);
      Result.AType := TVocType(GetByte(Ptr+6));
		  Exit;
		end;  
  {Vocabulary is sorted so if VocWord>AWord we will not find that word}
 	if AVocWord>Aword then Exit;
  Ptr := ptr+ 7;
 end; {While}
end;


procedure getPlayerOrders;
var i : word;
begin
 i := random(4);
 WriteText(getPcharMessage(DDBHeader.sysmessPos ,i+SM2));
 WriteText(''#13#10);
 ReadLn(inputBuffer);
 for i:= 0 to ConjunctionsCount - 1 do
  while (Pos(Conjunctions[i], inputBuffer)>0) do
    inputBuffer := StringReplace(inputBuffer, Conjunctions[i], '.');
 inputBuffer := StrUpper(inputBuffer);
end; 




function parse(Option:TFlagType):boolean;
var playerOrder : string;
	  orderWords : array[0..High(Byte)] of TWord;
	  orderWordCount : Byte;
    i : integer;
    AWordRecord : TWordRecord;
    Result : boolean;
    PronounNoun, PronounAdject : TFlagType;
begin
 Result := false;
 if (inputBuffer='') then getPlayerOrders;
 {Extract an order}
 playerOrder := '';
 i := 1;
 while (not (inputBuffer[i] in STANDARD_SEPARATORS)) and (i <= Length(inputBuffer)) do
 begin
  playerOrder := playerOrder + inputBuffer[i];
  i := i + 1;
 end;
 if (i>=Length(inputBuffer)) then inputBuffer := '' {If finished, we empty the inputBuffer}
							 else inputBuffer := Copy(inputBuffer, i + 1, 255); {If not , we set it to the remaining after the separator}

 
 orderWordCount := 0;
 {remove double spaces}
 while (Pos('  ', playerOrder)> 0) do playerOrder := StringReplace(playerOrder, '  ', ' ');

 {split order into words}
 for i:= 0 to High(Byte) do orderWords[i] := '';
 orderWordCount := 0;
 while playerOrder <> '' do
 begin
  if (Pos(' ', playerOrder)> 0) then
  begin
   orderWords[orderWordCount] := Copy(playerOrder, 1, Pos(' ', playerOrder) - 1);
   orderWordCount := orderWordCount + 1;
   playerOrder := Copy(playerOrder, Pos(' ', playerOrder) + 1, 255);
  end
  else
  begin
   orderWords[orderWordCount] := playerOrder;
   orderWordCount := orderWordCount + 1;
   playerOrder := '';
  end;
 end;

 {parse the order}

 {Preserve previous noun and adject in case they are needed}
 PronounNoun := getFlag(FPRONOUN);
 PronounAdject := getFlag(FPRONOUN_ADJECT);

 setflag(FVERB, NO_WORD);
 setFlag(FNOUN, NO_WORD);
 setFlag(FADJECT, NO_WORD);
 setFlag(FNOUN2, NO_WORD);
 setFlag(FADJECT2, NO_WORD);
 setFlag(FADVERB, NO_WORD);
 setFlag(FPREP, NO_WORD);

 i:= 0;
 while (i < orderWordCount) and (orderWords[i]<>'') do
 begin
  FindWord(orderWords[i], VOC_ANY, AWordRecord);
  if AWordRecord.ACode<> - 1 then
  begin
   if (AWordRecord.AType = VOC_VERB) and (getFlag(FVERB) = NO_WORD) then setFlag(FVERB,AWordRecord.ACode) else
   if (AWordRecord.AType = VOC_NOUN) and (getFlag(FNOUN) = NO_WORD) then setFlag(FNOUN,AWordRecord.ACode) else
   if (AWordRecord.AType = VOC_NOUN) and (getFlag(FNOUN2) = NO_WORD) then setFlag(FNOUN2,AWordRecord.ACode) else
   if (AWordRecord.AType = VOC_ADJECT) and (getFlag(FADJECT) = NO_WORD) then setFlag(FADJECT,AWordRecord.ACode) else
   if (AWordRecord.AType = VOC_ADJECT) and (getFlag(FADJECT2) = NO_WORD) then setFlag(FADJECT2,AWordRecord.ACode) else
   if (AWordRecord.AType = VOC_PREPOSITION) and (getFlag(FPREP) = NO_WORD) then setFlag(FPREP,AWordRecord.ACode) else
   if (AWordRecord.AType = VOC_ADVERB) and (getFlag(FADVERB) = NO_WORD) then setFlag(FADVERB,AWordRecord.ACode) else 
   if (AWordRecord.AType = VOC_PRONOUN) and (getFlag(FPRONOUN) = NO_WORD) then setFlag(FPRONOUN,AWordRecord.ACode);
   
  end;
  i := i + 1;
 end;
 {Convertible nouns}
 if (getFlag(FVERB)=NO_WORD) and (getFlag(FNOUN)<=LAST_CONVERTIBLE_NOUN) then
 begin
  setFlag(FVERB, getFlag(FNOUN));
  setflag(FNOUN, NO_WORD);
 end;
 {Mising verb but present noun, replace with previous verb}
 if (getFlag(FVERB)=NO_WORD) and (getFlag(FNOUN)<>NO_WORD) AND (PreviousVerb<>NO_WORD) then setFlag(FVERB, PreviousVerb);

{Pronouns and terminations}  (* Faltan las terminations *)
if (getFlag(FNOUN)=NO_WORD) and (getFlag(FPRONOUN)<>NO_WORD) then
begin
 setFlag(FNOUN, PronounNoun);
 setFlag(FADJECT, PronounAdject);
end;

 {Save noun and adject from LS to maybe be used in future orders}
 setFlag(FPRONOUN, getFlag(FNOUN));
 setFlag(FPRONOUN_ADJECT, getFlag(FADJECT));

 if (getFlag(FVERB)<>NO_WORD) then Result := true;
 parse := Result;
end;

begin
 PreviousVerb := NO_WORD;
end.