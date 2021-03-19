(* the flags table and accesing functions *)
{$I SETTINGS.INC}
unit flags;

interface

uses global;

const   FDARK=0;
        FCARRIED= 1;
        FMOUSE=29;
        FSCORE=30;
        FTURNS_LO=31;
        FTURNS_HI=32;
        FVERB = 33;
        FNOUN = 34;
        FADJECT=35;
        FADVERB=36;
        FOBJECTS_CONVEYABLE =37;
        FPLAYER = 38;
        FINPUT=41;
        FPROMPT=42;
        FPREP=43;
        FNOUN2=44;
        FADJECT2=45;
        FPRONOUN=46;
        FPRONOUN_ADJECT=47;
        FTIMEOUT=48;
        FTIMEOUT_CONTROL=49;
        FDOALL=50;
        FREFOBJ = 51;
        FPLAYER_STRENGTH=52;
        FOBJECT_PRINT_FLAGS=53;
        FREFOBJLOC = 54;
        FREFOBJWEIGHT = 55;
        FREFOBJCONTAINER = 56;
        FREFOBJWEARABLE = 57;
        FREFOBJATTR1 = 58;
        FREFOBJATTR2 = 59;
        FKEY1 =60;
        FKEY2 = 61;
        FSCREENMODE=62;
        FACTIVEWINDOW=63;

        MAX_FLAGS = 256;
        MAX_FLAG_VALUE = $FF;


function getFlag(index: word):TFlagType;
procedure setFlag(index: word; value: TFlagType);
function getFlagBit(index:word;bitno:byte): boolean;

procedure resetFlags; {Restore flag to initial values}
procedure RAMSaveFlags; {Copies the flags in a RAMSAVE slot}
procedure RAMLoadFlags(flagno: TFlagType); {Restores RAM saved copy up to flag flagno}

implementation

var flagsArray : array [0..MAX_FLAGS-1] of TFlagType;
    flagsArrayRAMSAVE : array [0..MAX_FLAGS-1] of TFlagType;
    
procedure RAMSaveFlags;
begin   
 move(flagsArray, flagsArrayRAMSAVE, sizeof(flagsArray));
end; 

procedure RAMLoadFlags(flagno: TFlagType);
var i : TFlagType;
begin   
 for i:= 0 to flagno do flagsArray[i] := flagsArrayRAMSAVE[i];
end; 

function getFlag(index: word):TFlagType;
begin
    getFlag := flagsArray[index];
end;

procedure resetFlags;
var i : integer;
begin
    for i := 0 to MAX_FLAGS-1 do setFlag(i, 0);
end;

procedure setFlag(index: word; value: TFlagType);
begin
    flagsArray[index] := value;
end;

function getFlagBit(index:word;bitno:byte): boolean;
begin
    getFlagBit := (getFlag(index) AND (1 SHL bitno)) <> 0;
end;

end.