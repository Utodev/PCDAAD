{$I SETTINGS.INC}
unit parser;

interface
uses global;

const WORD_LENGHT = 5;
      COMPLETE_WORD_LENGHT = 15;
	    STANDARD_SEPARATORS : set of char = ['.',',',';',':'];
      {$ifdef SPANISH}
      SPANISH_TERMINATIONS : array [0..3] of String = ('LO','LA','LOS','LAS');
      {$endif}
	    MAX_CONJUNCTIONS = 256;
      NUM_HISTORY_ORDERS = 20;

type TWord = String[WORD_LENGHT];
     TCompleteWord = String[COMPLETE_WORD_LENGHT];
type TVocType = (VOC_VERB,VOC_ADVERB,VOC_NOUN, VOC_ADJECT, VOC_PREPOSITION, VOC_CONJUGATION,  VOC_PRONOUN, VOC_ANY);
type TWordRecord = record
                    ACode: integer;
                    AType: TVocType;
                   end; 


{This string contains what has been received from the player input}   
{but when read, conjunctions are replaced with a dot to ease order}
{split later.}
var inputBuffer: String;
var inputHistory : array [0..NUM_HISTORY_ORDERS-1] of String;
    inputHistoryCount, inputHistoryPointer : Byte;
    useOrderInputFile: Boolean;
    orderInputFile: text;
    orderInputFileName: string;

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

{Request string from keyboard. Used by parser, but also for QUIT, SAVE, END, LOAD, etc.}
procedure getCommand;

{These two procedures bring order back from order history}
function getNextOrderHistory: string;
function getPreviousOrderHistory : String;
{And this one adds one more sentence}
procedure addToOrderHistory(Str: String);

{For debugging: gets the vocabulary word for a specific value and type}
function getVocabulary(AVocType: TVocType; aCode: integer): String;

{Initializes the input from file system}
procedure InitOrderFile;
{Finalizes the order file}
procedure CloseOrderFile;


implementation

uses ddb, flags, graph, errors, utils, messages, strings, condacts, ibmpc, log;

var PreviousVerb: TFlagType;
    playerOrderQuoted : string;
	  

{This array keeps the conjuctions provided by the DDB}
var Conjunctions : array [0..MAX_CONJUNCTIONS-1] of TWord;
   	ConjunctionsCount : Byte; 

procedure newtext;
begin
 inputBuffer := '';
end;

procedure InitOrderFile;
begin
if useOrderInputFile then
begin
  Assign(orderInputFile, orderInputFileName);
  Reset(orderInputFile);
  if (ioresult<>0) then Error(9,'Invalid or missing orders file');
end;  
end;

procedure CloseOrderFile;
begin
if useOrderInputFile then
begin
 Close(orderInputFile);
end;
end;

procedure InitializeParser;
var i, ptr : Word;
	AVocWord : TWord;
begin
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
 AWord := StrToUpper(AWord);
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

var KnownVocabulary:  array[Byte] of TWord;

function getVocabulary(AVocType: TVocType; aCode: integer): String;
var ptr : Word;
    AVocWord : TWord;
    i: integer;
begin
 if (aCode = MAX_FLAG_VALUE) then
 begin
  getVocabulary := '_';
  exit;
 end;

 if (AVocType = VOC_VERB) and (KnownVocabulary[aCode] <> '')  then
 begin
  getVocabulary := KnownVocabulary[aCode];
  exit;
 end;

 {search word by code/type} 
 Ptr := DDBHeader.vocabularyPos;
 while (GetByte(Ptr)<> 0) do
 begin
  if (TVocType(GetByte(Ptr+6)) = AVocType) and (GetByte(Ptr+5)=ACode) then
  begin
   AVocWord := '';
   for i := 0 to WORD_LENGHT -1 do 
     if ((GetByte(Ptr+i) XOR OFUSCATE_VALUE)<>32) 
      then AVocWord := AVocWord + CHR(GetByte(Ptr+i) XOR OFUSCATE_VALUE); 
   if (AVocType =VOC_VERB) then KnownVocabulary[aCode] := AVocWord;
   getVocabulary := AVocWord;
   exit;
  end ;
  Ptr := Ptr + 7;
 end; 
 if (AVocType = VOC_VERB) then KnownVocabulary[aCode] := '?' + inttostr(aCode) + '?';
 getVocabulary := KnownVocabulary[aCode];
end;

procedure DiagFlagDump;
var i: TFlagType;
    value : TFlagType;
    S: String;
    workPchar : array[0..10] of char;
begin
 for i := 0 to High(TFlagType) do
 begin
  value := getFlag(i);
  S := strpad(IntToStr(i),' ',3) + ':'  + IntToStr(Value) + ' ';
  StrPCopy(workPchar, S);
  WriteText(workPchar, true);
  if ((i mod 8) = 0) then CarriageReturn;
 end;
 if ((i mod 8) <> 0) then CarriageReturn;
end;

procedure Diagnostics(DiagStr: String);
var value, code : integer;
    valstr : array[0..2] of char;
begin
 if (DiagStr = '+') then DiagFlagDump
 else
 begin
  Val(Copy(DiagStr, 2, 255), value, code);
  if (code=0) and (value>=0) and (value<=high(TFlagType)) then 
  begin
    value := getFlag(value);
    StrPCopy(valstr, inttostr(value) + #10);
    WriteText(valstr, true);
  end 
  else WriteText('Invalid diagnostics input.', true);
 end; 
end;

procedure getCommand;
begin
 inputBuffer := '';
 if (useOrderInputFile) then
 while (inputBuffer ='') and  (not eof(orderInputFile)) do
 begin
  ReadLn(orderInputFile, inputBuffer);
 end;
 if inputBuffer = '' then
 begin
  {$ifdef VGA}
  Sysmess(SM33); {the prompt}
  ReadText(inputBuffer);
  Windows[ActiveWindow]. LastPauseLine := 0;
  {$else}
  ReadLn(inputBuffer);
  {$endif}
 end
 else WriteTextPas(#13'>' + inputBuffer + #13, false);
end;

procedure getPlayerOrders;
var i : word;
begin
 repeat
 getCommand;
  if (Length(inputBuffer)>0) and (inputBuffer[1]='+') then
  begin
    Diagnostics(inputBuffer);
    inputBuffer := '';
  end;
 until inputBuffer<>'';
 for i:= 0 to ConjunctionsCount - 1 do
  while (Pos(Conjunctions[i], inputBuffer)>0) do
    inputBuffer := StringReplace(inputBuffer, Conjunctions[i], '.');
 inputBuffer := StrToUpper(inputBuffer);
end; 




function parse(Option:TFlagType):boolean;
var orderWords : array[0..High(Byte)] of TCompleteWord;
	  orderWordCount : Byte;
    i, j : integer;
    AWordRecord : TWordRecord;
    ASearchWord : TWord;
    Result : boolean;
    PronounInSentence : Boolean;
    playerOrder : string;
begin

if (Option = 0) then (* parse 0, get order from the player or from orders buffer *)
begin
 Result := false;
 if (inputBuffer='') then
 begin
  i := random(4);
  Sysmess(SM2 + i);
  getPlayerOrders;
 end; 
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
 
  {Try to find a quoted sentence in the order. If found, text before the quoted setence goes to playerOrder,
   and text after the quotes is stored in global variable playerOrderQuoted, in case it is later required by PARSE 1}
  if (Pos('"', playerOrder)>0) then
  begin
    playerOrderQuoted := Copy(playerOrder, Pos('"', playerOrder) + 1, 255);
    if (Pos('"', playerOrderQuoted)>0) then playerOrderQuoted := Copy(playerOrderQuoted, 1, Pos('"', playerOrderQuoted) - 1);
    playerOrder := Copy(playerOrder, 1, Pos('"', playerOrder) - 1);
    {Because orginal interpreters make a difference betwee 'SAY JOHN'  and 'SAY JOHN ""'}
    if (playerOrderQuoted='') then playerOrderQuoted := ' '; 
  end
  else  playerOrderQuoted := '';
end 
else 
begin
 playerOrder := playerOrderQuoted; (* PARSE 1, get order from a quoted sentence in the current LS *)
 
 if (playerOrder = '')
 then
 begin
  parse := false; (* To force next condact execution *)
  exit;
 end;
end; 

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

 setflag(FVERB, NO_WORD);
 setFlag(FNOUN, NO_WORD);
 setFlag(FADJECT, NO_WORD);
 setFlag(FNOUN2, NO_WORD);
 setFlag(FADJECT2, NO_WORD);
 setFlag(FADVERB, NO_WORD);
 setFlag(FPREP, NO_WORD);
 PronounInSentence := false;

 i:= 0;
 while (i < orderWordCount) and (orderWords[i]<>'') do
 begin
  ASearchWord := orderWords[i]; {Convert TCompleteWord to TWord}
  FindWord(ASearchWord, VOC_ANY, AWordRecord);
  if AWordRecord.ACode<> - 1 then
  begin
   if (AWordRecord.AType = VOC_VERB) and (getFlag(FVERB) = NO_WORD) then setFlag(FVERB,AWordRecord.ACode) else
   if (AWordRecord.AType = VOC_NOUN) and (getFlag(FNOUN) = NO_WORD) then setFlag(FNOUN,AWordRecord.ACode) else
   if (AWordRecord.AType = VOC_NOUN) and (getFlag(FNOUN2) = NO_WORD) then setFlag(FNOUN2,AWordRecord.ACode) else
   if (AWordRecord.AType = VOC_ADJECT) and (getFlag(FADJECT) = NO_WORD) then setFlag(FADJECT,AWordRecord.ACode) else
   if (AWordRecord.AType = VOC_ADJECT) and (getFlag(FADJECT2) = NO_WORD) then setFlag(FADJECT2,AWordRecord.ACode) else
   if (AWordRecord.AType = VOC_PREPOSITION) and (getFlag(FPREP) = NO_WORD) then setFlag(FPREP,AWordRecord.ACode) else
   if (AWordRecord.AType = VOC_ADVERB) and (getFlag(FADVERB) = NO_WORD) then setFlag(FADVERB,AWordRecord.ACode)
   {If English, pronouns work independently, if Spanish, pronouns are applied a pronominal suffixes}
   {$ifndef SPANISH}
   else if (AWordRecord.AType = VOC_PRONOUN) and (not PronounInSentence) then PronounInSentence := true;
   {$else}
   ;
   if (AWordRecord.AType = VOC_VERB) and (not PronounInSentence) then
   begin
    j := 0;
    while (j<4) and (not PronounInSentence) do
    begin
      {check if the verb ends with one of the pronominal suffixes}
      if (Pos(SPANISH_TERMINATIONS[j], StrToUpper(orderWords[i])) 
          = 1 + Length(orderWords[i]) - Length(SPANISH_TERMINATIONS[j]))
      then
      begin
      {If we have a word ending with pronominal suffixes, we need to check whether the word is a verb 
      also without the termination, to avoid the HABLA bug where "LA" is part of the verb habLAr and
      not a suffix. So first we remove the termination:}
      ASearchWord := Copy(orderWords[i], 1, Length(orderWords[i])-Length(SPANISH_TERMINATIONS[j]));
      {Then check if still can be recognized as a verb}
      FindWord(ASearchWord, VOC_VERB, AWordRecord);
      if AWordRecord.ACode<>-1 then PronounInSentence := true;
      {Please notice the word has to be first recognized as verb, so all Spanish verbs which are not
       5 characters long should have synonyms including the suffix or part of it: DAR->DARLO, COGE->COGEL}
      end;
      j := j +1;
    end;  (* loop over the terminations *)
   end; (* if a Verb and no pronoun *) 
   {$endif}
   
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

 {Apply pronouns or terminations if needed}  
 if (getFlag(FNOUN)=NO_WORD) and (PronounInSentence) and (getFlag(FPRONOUN)<>NO_WORD) then
 begin
  setFlag(FNOUN, getFlag(FPRONOUN));
  setFlag(FADJECT, getFlag(FPRONOUN_ADJECT));
 end;

 {Save noun and adject from LS to maybe be used in future orders, unless they are proper names ( < 50 )}
 if (getFlag(FNOUN)>=50) and (getFlag(FNOUN)<>NO_WORD) then
 begin
  setFlag(FPRONOUN, getFlag(FNOUN));
  setFlag(FPRONOUN_ADJECT, getFlag(FADJECT));
 end;

 {Preserve verb to be used by next sentence}
 if (getFlag(FVERB)<>NO_WORD) then  PreviousVerb := getFlag(FVERB);

 if (getFlag(FVERB)<>NO_WORD) OR (getFlag(FNOUN)<>NO_WORD) then Result := true;
 parse := Result or (option>0);
end;

function getNextOrderHistory: string;
begin
 if (inputHistoryPointer <> 0) then getNextOrderHistory:= inputHistory[inputHistoryPointer-1    ] 
                               else getNextOrderHistory:= '';
 if (inputHistoryPointer <> 0) then inputHistoryPointer :=  inputHistoryPointer - 1;
end;

function getPreviousOrderHistory : String;
begin
 if (inputHistoryPointer <> inputHistoryCount) then
 begin
   inputHistoryPointer :=  inputHistoryPointer + 1;
   getPreviousOrderHistory:= inputHistory[inputHistoryPointer];
 end else getPreviousOrderHistory:='';
 
end;
procedure addToOrderHistory(Str: String);
var i : byte;
begin
 if inputHistoryCount = NUM_HISTORY_ORDERS then 
 begin
  for i := 0 to NUM_HISTORY_ORDERS - 2 do inputHistory[i] := inputHistory[i + 1];
  inputHistoryCount := NUM_HISTORY_ORDERS - 1;
  inputHistoryPointer := inputHistoryCount;
 end;
 inputHistory[inputHistoryCount] := Str;
 inputHistoryPointer := inputHistoryCount;
 inputHistoryCount := inputHistoryCount  + 1; 
end;


var i : word;
begin
 PreviousVerb := NO_WORD;
 inputHistoryCount := 0;
 inputHistoryPointer := 0;
 for i := 0 to 255 do KnownVocabulary[i]:='';
 useOrderInputFile := false;
end.