{$I SETTINGS.INC}
unit parser;

interface
uses global;

const WORD_LENGHT = 5;
	  STANDARD_SEPARATORS : set of char = ['.',',',';',':','"',''''];
	  MAX_CONJUNCTIONS = 256;

type TWord = String[WORD_LENGHT];
type TVocType = (VOC_VERB,VOC_ADVERB,VOC_NOUN, VOC_ADJECT, VOC_PREPOSITION, VOC_CONJUGATION,  VOC_PRONOUN, VOC_ANY);


{Returns the code for a specific word of a specific type, or any}
{type if AVocType= VOC_ANY. If not found returns -1}
function FindWord(AWord: TWord; AVocType : TVocType): integer;

{Extract an order from inputBuffer of request an order if empty}
{Then parsers first order in the buffer and sets flags }
procedure parse(Option:TFlagType);

{ Initializes the parser by reading conjunctions from the DDB}
procedure InitializeParser;

{Clears the inputBufffer}
procedure newtext;


implementation


uses ddb, flags, graph, errors, utils;

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



function FindWord(AWord: TWord; AVocType : TVocType): integer;
var i, ptr : Word;
	AVocWord : TWord;
begin
 Ptr := DDBHeader.vocabularyPos;
 
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
		  FindWord := GetByte(Ptr+5);
		  Exit;
		end;  

 {Vocabulary is sorted so if VocWord>AWord we will not find that word}
	if AVocWord>Aword then 
	begin
	FindWord := -1;
	Exit;
	end;
end; {While}

FindWord := -1;
end;


procedure getPlayerOrders;
var i : word;
begin
 ReadLn(inputBuffer);
 for i:= 0 to ConjunctionsCount - 1 do
  while (Pos(Conjunctions[i], inputBuffer)>0) do
    inputBuffer := StringReplace(inputBuffer, Conjunctions[i], '.');
end; 

procedure parse(Option:TFlagType);
var playerOrder : string;
	orderWords : array[0..High(Byte)] of TWord;
	orderWordCount : Byte;
    i : integer;
begin
 if (inputBuffer='') then getPlayerOrders;
 {Extract an order}
 playerOrder := '';
 i := 0;
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
 for i:= 1 to orderWordCount - 1 do WriteLn(orderWords[i]);
 (* FALTA PARSEAR *)
 
end;


end.