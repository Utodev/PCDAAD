{$I SETTINGS.INC}
(* Functions to load the DDB file and access data in it*)
unit ddb;



interface

uses global;

CONST OFUSCATE_VALUE = $FF;

type TDDBheader = record
	version: byte;
	targetMachineLanguage: byte;
	the95: byte;
	numObj: byte;
	numLoc: byte;
	numMsg: byte;
	numSys: byte;
	numPro: byte;
	tokenPos: word;
	processPos: word;
	objectPos: word;
	locationPos: word;
	messagePos: word;
	sysmessPos: word;
	connectionPos: word;
	vocabularyPos: word;
	objInitiallyAtPos: word;
	objNamePos: word;
	objWeightContWearPos: word;
	objAttributesPos: word;
	fileLength: word;
end;

var DDBHeader : TDDBheader;
    ProcessPTR, EntryPTR, CondactPTR : Word;
    DoallPTR : Word; {0 if DOALL not active, points to condact after DOALL otherwise}
    DoallEntryPTR : Word;
    DoallLocation : Word;

function loadDDB(filename: String) : boolean; {Loads a DDB file}
function getByte(address: Word): byte; {get byte at address from DDB}
function getWord(address: Word): word; {get word at address from DDB}
procedure resetProcesses; {restarts pointers to restart game}
procedure ConsumeProcess; {Goes to last entry of process}

procedure MoveToDDB(var buffer; offset, size: word); {Fucntions to pacth the DDB, mainly for XMEssages}
procedure MoveFromDDB(var buffer; offset, size: word);

function IsSpanish: boolean;


var DDBRAM : pointer;

implementation

uses utils;

    

(* Loads DDB file "filename" and returns true if it is present and size <=64K *)
function loadDDB(filename: String) : boolean;
var ddbFile: file;
    ddbSize : longint;
begin
    Assign(ddbFile, filename);
    loadDDB := false;
    Reset(ddbFile, 1);
    if (ioresult = 0) then
    begin
        ddbSize := filesize(ddbFile);
        if (ddbSize<=$FFFF) and (ddbSize > sizeof(TDDBheader)) then
        begin
            BlockRead(ddbFile, DDBHeader, Sizeof(TDDBHeader));
            Close(ddbFile);
            Reset(ddbFile, 1);
            GetMem(DDBRAM, $FFFF);
            FillChar(DDBRAM^, $FFFF, 0);
            BlockRead(ddbFile, DDBRAM^, ddbSize);
            loadDDB := true;
        end;
    end;
end;

procedure resetProcesses;
begin
    DoallPTR := 0;
    DoallEntryPTR := 0; {Not really necessery}
    CondactPTR := 0;
    ProcessPTR :=  DDBHeader.processPos;
    EntryPTR :=  getWord(ProcessPTR);
end;    


(*Returns a byte from the DDB file *)
function getByte(address: Word): byte;
begin
    {TP allows a maximum of 65535 bytes for GetMem, so address $FFFF does not exist}
    if (address > $FFFE) then getByte := 0              
                         else getByte := byte(pointer(DWORD(DDBRAM)+address)^);
end;

(*Returns a word from the DDB file *)
function getWord(address: Word): word;
begin
  getWord := getByte(address) + 256 * getByte(address + 1);
end;

procedure ConsumeProcess;
begin
 while (GetByte(EntryPtr) <> END_OF_PROCESS_MARK) do EntryPtr := EntryPtr + 4;
 EntryPtr := EntryPtr - 4;
end;

procedure MoveToDDB(var buffer; offset, size: word);
begin
 Move(buffer, pointer(DWORD(DDBRAM)+offset)^, size);
end;

procedure MoveFromDDB(var buffer; offset, size: word);
begin
 Move(pointer(DWORD(DDBRAM)+offset)^, buffer, size);
end;

function IsSpanish: boolean;
begin
 IsSpanish := (DDBHeader.targetMachineLanguage and 1) <> 0;
end;

begin
end.