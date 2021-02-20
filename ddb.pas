(* Functions to load the DDB file and access data in it*)
unit ddb;

{$I SETTINGS.INC}


interface



uses global;

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

function loadDDB(filename: String) : boolean; {Loads a DDB file}
function getByte(address: Word): byte; {get byte at address from DDB}
function getWord(address: Word): word; {get word at address from DDB}
procedure resetProcesses; {restarts pointers to restart game}


implementation

var DDBRAM : pointer;
    

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
            GetMem(DDBRAM, $FFFF);
            FillChar(DDBRAM^, $FFFF, 0);
            BlockRead(ddbFile, DDBHeader, Sizeof(TDDBHeader));
            Seek(ddbFile, 0);
            BlockRead(ddbFile, DDBRAM^, ddbSize);
            Close(ddbFile);
            loadDDB := true;
        end;
    end;
end;

procedure resetProcesses;
begin
    DoallPTR := 0;
    CondactPTR := 0;
    ProcessPTR :=  getWord(DDBHeader.processPos);
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

end.