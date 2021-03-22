{$I SETTINGS.INC}
(* All the condacts stuff, including implementation of condacts *)

unit condacts;

interface

uses global;

const MAX_CONDACTS = 128;

type TCondactType = record
                        condactName : String;
                        condactRoutine : procedure;
                        numParams : byte;
                     end;   

     TCondactTable = array[0..MAX_CONDACTS - 1] of TCondactType;
     TOpcodeType = byte;
     
var condactResult : boolean; {Condacts should update this to false when it's a condition and fails}
    Parameter1: TFlagType;
    Parameter2: TFlagType;
    Done: boolean;
    
procedure _AT;
procedure _NOTAT;
procedure _ATGT;
procedure _ATLT;
procedure _PRESENT;
procedure _ABSENT;
procedure _WORN;
procedure _NOTWORN;
procedure _CARRIED;
procedure _NOTCARR;
procedure _CHANCE;
procedure _ZERO;
procedure _NOTZERO;
procedure _EQ;
procedure _GT;
procedure _LT;
procedure _ADJECT1;
procedure _ADVERB;
procedure _SFX;
procedure _DESC;
procedure _QUIT;
procedure _END;
procedure _DONE;
procedure _OK;
procedure _ANYKEY;
procedure _SAVE;
procedure _LOAD;
procedure _DPRINT;
procedure _DISPLAY;
procedure _CLS;
procedure _DROPALL;
procedure _AUTOG;
procedure _AUTOD;
procedure _AUTOW;
procedure _AUTOR;
procedure _PAUSE;
procedure _SYNONYM;
procedure _GOTO;
procedure _MESSAGE;
procedure _REMOVE;
procedure _GET;
procedure _DROP;
procedure _WEAR;
procedure _DESTROY;
procedure _CREATE;
procedure _SWAP;
procedure _PLACE;
procedure _SET;
procedure _CLEAR;
procedure _PLUS;
procedure _MINUS;
procedure _LET;
procedure _NEWLINE;
procedure _PRINT;
procedure _SYSMESS;
procedure _ISAT;
procedure _SETCO;
procedure _SPACE;
procedure _HASAT;
procedure _HASNAT;
procedure _LISTOBJ;
procedure _EXTERN;
procedure _RAMSAVE;
procedure _RAMLOAD;
procedure _BEEP;
procedure _PAPER;
procedure _INK;
procedure _BORDER;
procedure _PREP;
procedure _NOUN2;
procedure _ADJECT2;
procedure _ADD;
procedure _SUB;
procedure _PARSE;
procedure _LISTAT;
procedure _PROCESS;
procedure _SAME;
procedure _MES;
procedure _WINDOW;
procedure _NOTEQ;
procedure _NOTSAME;
procedure _MODE;
procedure _WINAT;
procedure _TIME;
procedure _PICTURE;
procedure _DOALL;
procedure _MOUSE;
procedure _GFX;
procedure _ISNOTAT;
procedure _WEIGH;
procedure _PUTIN;
procedure _TAKEOUT;
procedure _NEWTEXT;
procedure _ABILITY;
procedure _WEIGHT;
procedure _RANDOM;
procedure _INPUT;
procedure _SAVEAT;
procedure _BACKAT;
procedure _PRINTAT;
procedure _WHATO;
procedure _CALL;
procedure _PUTO;
procedure _NOTDONE;
procedure _AUTOP;
procedure _AUTOT;
procedure _MOVE;
procedure _WINSIZE;
procedure _REDO;
procedure _CENTRE;
procedure _EXIT;
procedure _INKEY;
procedure _BIGGER;
procedure _SMALLER;
procedure _ISDONE;
procedure _ISNDONE;
procedure _SKIP;
procedure _RESTART;
procedure _TAB;
procedure _COPYOF;
procedure _COPYOO;
procedure _COPYFO;
procedure _dumb;
procedure _COPYFF;
procedure _COPYBF;
procedure _RESET;


const condactTable : TCondactTable = (
(condactName: 'AT     '; condactRoutine: _AT     ; numParams: 1), {   0 $00}
(condactName: 'NOTAT  '; condactRoutine: _NOTAT  ; numParams: 1), {   1 $01}
(condactName: 'ATGT   '; condactRoutine: _ATGT   ; numParams: 1), {   2 $$02}
(condactName: 'ATLT   '; condactRoutine: _ATLT   ; numParams: 1), {   3 $03}
(condactName: 'PRESENT'; condactRoutine: _PRESENT; numParams: 1), {   4 $04}
(condactName: 'ABSENT '; condactRoutine: _ABSENT ; numParams: 1), {   5 $05}
(condactName: 'WORN   '; condactRoutine: _WORN   ; numParams: 1), {   6 $06}
(condactName: 'NOTWORN'; condactRoutine: _NOTWORN; numParams: 1), {   7 $07}
(condactName: 'CARRIED'; condactRoutine: _CARRIED; numParams: 1), {   8 $08}
(condactName: 'NOTCARR'; condactRoutine: _NOTCARR; numParams: 1), {   9 $09}
(condactName: 'CHANCE '; condactRoutine: _CHANCE ; numParams: 1), {  10 $0A}
(condactName: 'ZERO   '; condactRoutine: _ZERO   ; numParams: 1), {  11 $0B}
(condactName: 'NOTZERO'; condactRoutine: _NOTZERO; numParams: 1), {  12 $0C}
(condactName: 'EQ     '; condactRoutine: _EQ     ; numParams: 2), {  13 $0D}
(condactName: 'GT     '; condactRoutine: _GT     ; numParams: 2), {  14 $0E}
(condactName: 'LT     '; condactRoutine: _LT     ; numParams: 2), {  15 $0F}
(condactName: 'ADJECT1'; condactRoutine: _ADJECT1; numParams: 1), {  16 $10}
(condactName: 'ADVERB '; condactRoutine: _ADVERB ; numParams: 1), {  17 $11}
(condactName: 'SFX    '; condactRoutine: _SFX    ; numParams: 2), {  18 $12}
(condactName: 'DESC   '; condactRoutine: _DESC   ; numParams: 1), {  19 $13}
(condactName: 'QUIT   '; condactRoutine: _QUIT   ; numParams: 0), {  20 $14}
(condactName: 'END    '; condactRoutine: _END    ; numParams: 0), {  21 $15}
(condactName: 'DONE   '; condactRoutine: _DONE   ; numParams: 0), {  22 $16}
(condactName: 'OK     '; condactRoutine: _OK     ; numParams: 0), {  23 $17}
(condactName: 'ANYKEY '; condactRoutine: _ANYKEY ; numParams: 0), {  24 $18}
(condactName: 'SAVE   '; condactRoutine: _SAVE   ; numParams: 1), {  25 $19}
(condactName: 'LOAD   '; condactRoutine: _LOAD   ; numParams: 1), {  26 $1A}
(condactName: 'DPRINT '; condactRoutine: _DPRINT ; numParams: 1), {  27 $1B}
(condactName: 'DISPLAY'; condactRoutine: _DISPLAY; numParams: 1), {  28 $1C}
(condactName: 'CLS    '; condactRoutine: _CLS    ; numParams: 0), {  29 $1D}
(condactName: 'DROPALL'; condactRoutine: _DROPALL; numParams: 0), {  30 $1E}
(condactName: 'AUTOG  '; condactRoutine: _AUTOG  ; numParams: 0), {  31 $1F}
(condactName: 'AUTOD  '; condactRoutine: _AUTOD  ; numParams: 0), {  32 $20}
(condactName: 'AUTOW  '; condactRoutine: _AUTOW  ; numParams: 0), {  33 $21}
(condactName: 'AUTOR  '; condactRoutine: _AUTOR  ; numParams: 0), {  34 $22}
(condactName: 'PAUSE  '; condactRoutine: _PAUSE  ; numParams: 1), {  35 $23}
(condactName: 'SYNONYM'; condactRoutine: _SYNONYM; numParams: 2), {  36 $24}
(condactName: 'GOTO   '; condactRoutine: _GOTO   ; numParams: 1), {  37 $25}
(condactName: 'MESSAGE'; condactRoutine: _MESSAGE; numParams: 1), {  38 $26}
(condactName: 'REMOVE '; condactRoutine: _REMOVE ; numParams: 1), {  39 $27}
(condactName: 'GET    '; condactRoutine: _GET    ; numParams: 1), {  40 $28}
(condactName: 'DROP   '; condactRoutine: _DROP   ; numParams: 1), {  41 $29}
(condactName: 'WEAR   '; condactRoutine: _WEAR   ; numParams: 1), {  42 $2A}
(condactName: 'DESTROY'; condactRoutine: _DESTROY; numParams: 1), {  43 $2B}
(condactName: 'CREATE '; condactRoutine: _CREATE ; numParams: 1), {  44 $2C}
(condactName: 'SWAP   '; condactRoutine: _SWAP   ; numParams: 2), {  45 $2D}
(condactName: 'PLACE  '; condactRoutine: _PLACE  ; numParams: 2), {  46 $2E}
(condactName: 'SET    '; condactRoutine: _SET    ; numParams: 1), {  47 $2F}
(condactName: 'CLEAR  '; condactRoutine: _CLEAR  ; numParams: 1), {  48 $30}
(condactName: 'PLUS   '; condactRoutine: _PLUS   ; numParams: 2), {  49 $31}
(condactName: 'MINUS  '; condactRoutine: _MINUS  ; numParams: 2), {  50 $32}
(condactName: 'LET    '; condactRoutine: _LET    ; numParams: 2), {  51 $33}
(condactName: 'NEWLINE'; condactRoutine: _NEWLINE; numParams: 0), {  52 $34}
(condactName: 'PRINT  '; condactRoutine: _PRINT  ; numParams: 1), {  53 $35}
(condactName: 'SYSMESS'; condactRoutine: _SYSMESS; numParams: 1), {  54 $36}
(condactName: 'ISAT   '; condactRoutine: _ISAT   ; numParams: 2), {  55 $37}
(condactName: 'SETCO  '; condactRoutine: _SETCO  ; numParams: 1), {  56 $38}
(condactName: 'SPACE  '; condactRoutine: _SPACE  ; numParams: 1), {  57 $39}
(condactName: 'HASAT  '; condactRoutine: _HASAT  ; numParams: 1), {  58 $3A}
(condactName: 'HASNAT '; condactRoutine: _HASNAT ; numParams: 1), {  59 $3B}
(condactName: 'LISTOBJ'; condactRoutine: _LISTOBJ; numParams: 0), {  60 $3C}
(condactName: 'EXTERN '; condactRoutine: _EXTERN ; numParams: 2), {  61 $3D}
(condactName: 'RAMSAVE'; condactRoutine: _RAMSAVE; numParams: 0), {  62 $3E}
(condactName: 'RAMLOAD'; condactRoutine: _RAMLOAD; numParams: 1), {  63 $3F}
(condactName: 'BEEP   '; condactRoutine: _BEEP   ; numParams: 2), {  64 $40}
(condactName: 'PAPER  '; condactRoutine: _PAPER  ; numParams: 1), {  65 $41}
(condactName: 'INK    '; condactRoutine: _INK    ; numParams: 1), {  66 $42}
(condactName: 'BORDER '; condactRoutine: _BORDER ; numParams: 1), {  67 $43}
(condactName: 'PREP   '; condactRoutine: _PREP   ; numParams: 1), {  68 $44}
(condactName: 'NOUN2  '; condactRoutine: _NOUN2  ; numParams: 1), {  69 $45}
(condactName: 'ADJECT2'; condactRoutine: _ADJECT2; numParams: 1), {  70 $46}
(condactName: 'ADD    '; condactRoutine: _ADD    ; numParams: 2), {  71 $47}
(condactName: 'SUB    '; condactRoutine: _SUB    ; numParams: 2), {  72 $48}
(condactName: 'PARSE  '; condactRoutine: _PARSE  ; numParams: 1), {  73 $49}
(condactName: 'LISTAT '; condactRoutine: _LISTAT ; numParams: 1), {  74 $4A}
(condactName: 'PROCESS'; condactRoutine: _PROCESS; numParams: 1), {  75 $4B}
(condactName: 'SAME   '; condactRoutine: _SAME   ; numParams: 2), {  76 $4C}
(condactName: 'MES    '; condactRoutine: _MES    ; numParams: 1), {  77 $4D}
(condactName: 'WINDOW '; condactRoutine: _WINDOW ; numParams: 1), {  78 $4E}
(condactName: 'NOTEQ  '; condactRoutine: _NOTEQ  ; numParams: 2), {  79 $4F}
(condactName: 'NOTSAME'; condactRoutine: _NOTSAME; numParams: 2), {  80 $50}
(condactName: 'MODE   '; condactRoutine: _MODE   ; numParams: 1), {  81 $51}
(condactName: 'WINAT  '; condactRoutine: _WINAT  ; numParams: 2), {  82 $52}
(condactName: 'TIME   '; condactRoutine: _TIME   ; numParams: 2), {  83 $53}
(condactName: 'PICTURE'; condactRoutine: _PICTURE; numParams: 1), {  84 $54}
(condactName: 'DOALL  '; condactRoutine: _DOALL  ; numParams: 1), {  85 $55}
(condactName: 'MOUSE  '; condactRoutine: _MOUSE  ; numParams: 1), {  86 $56}
(condactName: 'GFX    '; condactRoutine: _GFX    ; numParams: 2), {  87 $57}
(condactName: 'ISNOTAT'; condactRoutine: _ISNOTAT; numParams: 2), {  88 $58}
(condactName: 'WEIGH  '; condactRoutine: _WEIGH  ; numParams: 2), {  89 $59}
(condactName: 'PUTIN  '; condactRoutine: _PUTIN  ; numParams: 2), {  90 $5A}
(condactName: 'TAKEOUT'; condactRoutine: _TAKEOUT; numParams: 2), {  91 $5B}
(condactName: 'NEWTEXT'; condactRoutine: _NEWTEXT; numParams: 0), {  92 $5C}
(condactName: 'ABILITY'; condactRoutine: _ABILITY; numParams: 2), {  93 $5D}
(condactName: 'WEIGHT '; condactRoutine: _WEIGHT ; numParams: 1), {  94 $5E}
(condactName: 'RANDOM '; condactRoutine: _RANDOM ; numParams: 1), {  95 $5F}
(condactName: 'INPUT  '; condactRoutine: _INPUT  ; numParams:21), {  96 $60}
(condactName: 'SAVEAT '; condactRoutine: _SAVEAT ; numParams: 0), {  97 $61}
(condactName: 'BACKAT '; condactRoutine: _BACKAT ; numParams: 0), {  98 $62}
(condactName: 'PRINTAT'; condactRoutine: _PRINTAT; numParams: 2), {  99 $63}
(condactName: 'WHATO  '; condactRoutine: _WHATO  ; numParams: 0), { 100 $64}
(condactName: 'CALL   '; condactRoutine: _CALL   ; numParams: 1), { 101 $65}
(condactName: 'PUTO   '; condactRoutine: _PUTO   ; numParams: 1), { 102 $66}
(condactName: 'NOTDONE'; condactRoutine: _NOTDONE; numParams: 0), { 103 $67}
(condactName: 'AUTOP  '; condactRoutine: _AUTOP  ; numParams: 1), { 104 $68}
(condactName: 'AUTOT  '; condactRoutine: _AUTOT  ; numParams: 1), { 105 $69}
(condactName: 'MOVE   '; condactRoutine: _MOVE   ; numParams: 1), { 106 $6A}
(condactName: 'WINSIZE'; condactRoutine: _WINSIZE; numParams: 2), { 107 $6B}
(condactName: 'REDO   '; condactRoutine: _REDO   ; numParams: 0), { 108 $6C}
(condactName: 'CENTRE '; condactRoutine: _CENTRE ; numParams: 0), { 109 $6D}
(condactName: 'EXIT   '; condactRoutine: _EXIT   ; numParams: 1), { 110 $6E}
(condactName: 'INKEY  '; condactRoutine: _INKEY  ; numParams: 0), { 111 $6F}
(condactName: 'BIGGER '; condactRoutine: _BIGGER ; numParams: 2), { 112 $70}
(condactName: 'SMALLER'; condactRoutine: _SMALLER; numParams: 2), { 113 $71}
(condactName: 'ISDONE '; condactRoutine: _ISDONE ; numParams: 0), { 114 $72}
(condactName: 'ISNDONE'; condactRoutine: _ISNDONE; numParams: 0), { 115 $73}
(condactName: 'SKIP   '; condactRoutine: _SKIP   ; numParams: 1), { 116 $74}
(condactName: 'RESTART'; condactRoutine: _RESTART; numParams: 0), { 117 $75}
(condactName: 'TAB    '; condactRoutine: _TAB    ; numParams: 1), { 118 $76}
(condactName: 'COPYOF '; condactRoutine: _COPYOF ; numParams: 2), { 119 $77}
(condactName: 'dumb   '; condactRoutine: _dumb   ; numParams: 0), { 120 $78}
(condactName: 'COPYOO '; condactRoutine: _COPYOO ; numParams: 2), { 121 $79}
(condactName: 'dumb   '; condactRoutine: _dumb   ; numParams: 0), { 122 $7A}
(condactName: 'COPYFO '; condactRoutine: _COPYFO ; numParams: 2), { 123 $7B}
(condactName: 'dumb   '; condactRoutine: _dumb   ; numParams: 0), { 124 $7C}
(condactName: 'COPYFF '; condactRoutine: _COPYFF ; numParams: 2), { 125 $7D}
(condactName: 'COPYBF '; condactRoutine: _COPYBF ; numParams: 2), { 126 $7E}
(condactName: 'RESET  '; condactRoutine: _RESET  ; numParams: 0)  { 127 $7F}
);

procedure Sysmess(sysno: integer);


implementation



uses flags, ddb, objects, ibmpc, stack, messages, strings, errors, utils, parser, pcx, log;


(*****************************************************************************************)
(**************************************** AUX FUNCTIONS **********************************)
(*****************************************************************************************)

{SYSMESS is called often from other condact, so to ease calling Sysmess procedure is created}
procedure Sysmess(sysno: integer);
var saveParameter : TFlagType;
begin
 {preseve so in case it's used after sysmes() call, it is not altered}
 saveParameter := parameter1; 
 parameter1 := sysno;
 _SYSMESS;
 parameter1 := saveParameter;
end;

{LISTAT shows no message when no objects found, also the
following has to be fullfilled according manual: 

    Flag 53 holds object print flags
    7 - Set if any object printed as part of LISTOBJ or LISTAT
    6 - Set this to cause continuous object listing. i.e. LET 53 64
    will make PAW list objects on the same line forming a valid
    sentence.
}
procedure listObjects(locno: TFlagType; isLISTAT: boolean);
var count, listed : TFlagType;
    i : integer;
begin
 count := getObjectCountAt(locno);
 listed := 0;
 
 if (count> 0) then
 begin
    setFlag(FOBJECT_PRINT_FLAGS, getFlag(FOBJECT_PRINT_FLAGS) OR $80); {Set bit 7}
    
    if (not isLISTAT) then 
    begin
     Sysmess(SM1); {I can also see:} {Only for LISTOBJ}
     if ((getFlag(FOBJECT_PRINT_FLAGS) AND 64) = 0) then _NEWLINE;
    end;

    for  i := 0 to DDBHeader.numObj - 1 do
    begin
        if (getObjectLocation(i) = locno) then
        begin
            WriteText(getPcharMessage(DDBHeader.objectPos, i), false);
            listed := listed + 1;
            if ((getFlag(FOBJECT_PRINT_FLAGS) AND 64) <> 0) then
            begin {continuous listing}
                if (listed = count) then Sysmess(SM48)  {.\n}
                else if (listed = count - 1) then Sysmess(SM47) {"and"}
                else Sysmess(SM46); {, }
            end {continuous listing}
            else _NEWLINE;
        end; { if (getObjectLocation(i) = locno)}
    end  {for}
 end
 else
 begin {if no objects at the location}
  setFlag(FOBJECT_PRINT_FLAGS, getFlag(FOBJECT_PRINT_FLAGS) AND $7F); {Clear bit 7}
  if  isLISTAT then Sysmess(SM53); {"Nothing"}
 end;
 
end;


(*****************************************************************************************)
(****************************************** CONDACTS *************************************)
(*****************************************************************************************)

procedure _AT;
begin
    condactResult := getFlag(FPLAYER) = Parameter1;
end;

(*--------------------------------------------------------------------------------------*)
procedure _NOTAT;
begin
    condactResult := getFlag(FPLAYER) <> Parameter1;
end;

(*--------------------------------------------------------------------------------------*)
procedure _ATGT;
begin
    condactResult := getFlag(FPLAYER) > Parameter1;
end;

(*--------------------------------------------------------------------------------------*)
procedure _ATLT;
begin
    condactResult := getFlag(FPLAYER) < Parameter1;
end;

(*--------------------------------------------------------------------------------------*)
procedure _PRESENT;
var objectLocation : TLocationType;
begin
    objectLocation := getObjectLocation(parameter1);
    condactResult := (objectLocation = LOC_CARRIED) or (objectLocation = LOC_WORN) or (objectLocation = getFlag(FPLAYER)) ;
end;

(*--------------------------------------------------------------------------------------*)
procedure _ABSENT;
var objectLocation : TLocationType;
begin
    objectLocation := getObjectLocation(parameter1);
    condactResult := (objectLocation <> LOC_CARRIED) 
                       and (objectLocation <> LOC_WORN) 
                         and (objectLocation <> getFlag(FPLAYER)) ;
end;

(*--------------------------------------------------------------------------------------*)
procedure _WORN;
begin
    condactResult := getObjectLocation(parameter1) = LOC_WORN;
end;

(*--------------------------------------------------------------------------------------*)
procedure _NOTWORN;
begin
    condactResult := getObjectLocation(parameter1) <> LOC_WORN;
end;

(*--------------------------------------------------------------------------------------*)
procedure _CARRIED;
begin
    condactResult := getObjectLocation(parameter1) = LOC_CARRIED;
end;

(*--------------------------------------------------------------------------------------*)
procedure _NOTCARR;
begin
    condactResult := getObjectLocation(parameter1) <> LOC_CARRIED;
end;

(*--------------------------------------------------------------------------------------*)
procedure _CHANCE;
begin
 if (parameter1 > 100) then condactResult := false
                       else condactResult :=  random(101) <= parameter1;
end;

(*--------------------------------------------------------------------------------------*)
procedure _ZERO;
begin
    condactResult := getFlag(Parameter1) = 0;
end;

(*--------------------------------------------------------------------------------------*)
procedure _NOTZERO;
begin
    condactResult := getFlag(Parameter1) <> 0;
end;

(*--------------------------------------------------------------------------------------*)
procedure _EQ;
begin
    condactResult := getFlag(Parameter1) = Parameter2;
end;

(*--------------------------------------------------------------------------------------*)
procedure _GT;
begin
    condactResult := getFlag(Parameter1) > Parameter2;
end;

(*--------------------------------------------------------------------------------------*)
procedure _LT;
begin
    condactResult := getFlag(Parameter1) < Parameter2;
end;

(*--------------------------------------------------------------------------------------*)
procedure _ADJECT1;
begin
 condactResult := getFlag(FADJECT) = parameter1;
end;

(*--------------------------------------------------------------------------------------*)
procedure _ADVERB;
begin
 condactResult := getFlag(FADVERB) = parameter1;
end;

(*--------------------------------------------------------------------------------------*)
procedure _SFX;
begin
(* FALTA CONDACTO SFX *)
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _DESC;
begin
  WriteText(getPcharMessage(DDBHeader.locationPos, parameter1), false);
  done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _QUIT;
var YesResponse : char;
begin
   Sysmess(SM12); {"Are you sure? "}
   {Get first char of SM30, uppercased}
   YesResponse := upcase(char(getByte(getWord(DDBHeader.sysmessPos + 2 * SM30)) xor OFUSCATE_VALUE)); 
   inputBuffer := '';

   while inputBuffer = '' do
   begin
    getCommand;
    if (inputBuffer<> '') and (Upcase(inputBuffer[1])<>YesResponse) then condactResult := false;
   end; 
   inputBuffer := '';
   done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _END;
var NoResponse : char;
begin
   Sysmess(SM13); {"Are you sure? "}
   {Get first char of SM31, uppercased}
   NoResponse := upcase(char(getByte(getWord(DDBHeader.sysmessPos + 2 * SM31)) xor OFUSCATE_VALUE)); 
   inputBuffer := '';
   DoallPTR := 0;
   getCommand;
   if (inputBuffer<> '') and (Upcase(inputBuffer[1])=NoResponse) then parameter1:=0 else parameter1:=1;
   _EXIT;
end;

(*--------------------------------------------------------------------------------------*)
procedure _DONE;
begin
 done := true;
 ConsumeProcess; {Go to last entry}
 {force failure so we jump to next entry, which happens to be the mark of end of process}
 condactResult := false; 
end;

(*--------------------------------------------------------------------------------------*)
procedure _OK;
begin
  Sysmess(SM15); {OK}
 _DONE;
end;

(*--------------------------------------------------------------------------------------*)
procedure _ANYKEY;
var inkey :  word;
begin
 while not Keypressed do;
 inkey := ReadKey;
 done := true; 
 (* FALTA: SOPORTE DE TIMEOUT EN ANYKEY *)
end;

(*--------------------------------------------------------------------------------------*)
procedure _SAVE;
var Savegame : FILE;
    Header: String[32];
    Aux: Word;
begin
   condactResult := false;
   Sysmess(SM60); {Type in name of file}
   inputBuffer := '';
   getCommand;
   if (Pos('.',inputBuffer)=0) then inputBuffer := inputBuffer + '.sav';
   Assign(SaveGame, inputBuffer);
   inputBuffer := '';
   Rewrite(SaveGame, 1);
   if (ioresult<>0) then Sysmess(SM59){File name error.}
   else
   begin
    {Signature + version + filler}
    Header := 'UTO' + #0 + '                            ';
    BlockWrite(Savegame, Header[1], 32);
    {Save the flags}
    BlockWrite(SaveGame, flagsArray, Sizeof(flagsArray));
    {Save the object locations}
    BlockWrite(SaveGame, objLocations, Sizeof(objLocations));
    {Save the DOALLPtr}
    BlockWrite(SaveGame, DoallPTR, Sizeof(DoallPtr));
    {Save the window status}
    {BlockWrite(SaveGame, Windows, Sizeof(Windows));
    BlockWrite(SaveGame, ActiveWindow, 1);}
    Close(SaveGame);
    condactResult := true;
    done := true;
   end;
end;

(*--------------------------------------------------------------------------------------*)
procedure _LOAD;
var Savegame : FILE;
    Header: String[32];
    Aux: Word;
begin
   condactResult := false;
   Sysmess(SM60); {Type in name of file}
   inputBuffer := '';
   getCommand;
   if (Pos('.',inputBuffer)=0) then inputBuffer := inputBuffer + '.sav';
   Assign(SaveGame, inputBuffer);
   inputBuffer := '';
   Reset(SaveGame, 1);
   if (ioresult<>0) then Sysmess(SM57) {I/O Error.}
   else
   begin
    BlockRead(SaveGame, Header[1], 32);
    if (Header[1]<>'U') or (Header[2]<>'T') or (Header[3]<>'O') or (Header[4]<>#0) then Sysmess(SM57) {I/O Error}
    else
    begin
        {Load the flags}
        BlockRead(SaveGame, flagsArray, sizeof(flagsArray));
        {Load the object locations}
        BlockRead(SaveGame, objLocations, sizeof(objLocations));
        {Load the DOALLPtr}
        BlockRead(SaveGame, DoallPTR, Sizeof(DoallPtr));
        {Load the window status}
        {BlockRead(SaveGame, Windows, Sizeof(Windows));
        BlockRead(SaveGame, ActiveWindow, 1);}
        Close(SaveGame);
        done := true;
        condactResult := true;
    end;
   end; 
end;

(*--------------------------------------------------------------------------------------*)
procedure _DPRINT;
var value: Word;
    valstr : array[0..2] of char;
begin
    Value := getFlag(parameter1) + 256 * getFlag(parameter1 + 1);
    StrPCopy(valstr,inttostr(value));
    WriteText(valstr, false);
    done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _DISPLAY;
begin
(* FALTA CONDACTO DISPLAY *)
done := true;
end;

procedure _CLS;
begin
 ClearCurrentWindow;
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _DROPALL;
var nextObject : integer;
    here : TFlagType;
    locno : TFlagType;
begin
   here := getFlag(FPLAYER);
   for locno := LOC_CARRIED to LOC_WORN do
   begin
        nextObject := - 1;
        repeat
        nextObject := getNextObjectAt(nextObject, locno);
        if (nextObject<>MAX_OBJECT) then 
        begin 
            parameter1 := nextObject;
            parameter2 := here;
            _PLACE;
        end;
        until nextObject=MAX_OBJECT;
   end;
   done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _AUTOG;
var Noun, Adject : TFlagType;
begin
 Noun := getFlag(FNOUN);
 Adject := getFlag(FADJECT);
 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, getFlag(FPLAYER));
 if (Parameter1 <> MAX_OBJECT) then
 begin
  _GET;
  exit;
 end;
 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, LOC_WORN);
 if (Parameter1 <> MAX_OBJECT) then
 begin
  _GET;
  exit;
 end;
 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, LOC_CARRIED);
 if (Parameter1 <> MAX_OBJECT) then
 begin
  _GET;
  exit;
 end;
 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, MAX_LOCATION); {Any Location}
 if (Parameter1 <> MAX_OBJECT) then Sysmess(SM26) {There isn't one of those here.}
                               else Sysmess(SM8); {I can't do that.}
 newtext;
 _DONE;
 end;

(*--------------------------------------------------------------------------------------*)
procedure _AUTOD;
var Noun, Adject : TFlagType;
begin
 Noun := getFlag(FNOUN);
 Adject := getFlag(FADJECT);
 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, LOC_CARRIED);
 if (Parameter1 <> MAX_OBJECT) then
 begin
  _DROP;
  exit;
 end;

 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, LOC_WORN);
 if (Parameter1 <> MAX_OBJECT) then
 begin
  _DROP;
  exit;
 end;

 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, getFlag(FPLAYER));
 if (Parameter1 <> MAX_OBJECT) then
 begin
  _DROP;
  exit;
 end;

 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, MAX_LOCATION); {Any Location}
 if (Parameter1 <> MAX_OBJECT) then Sysmess(SM28) {I don't have one of those.}
                               else Sysmess(SM8); {I can't do that.}
 newtext;
 _DONE;
end;

(*--------------------------------------------------------------------------------------*)
procedure _AUTOW;
var Noun, Adject : TFlagType;
begin
 Noun := getFlag(FNOUN);
 Adject := getFlag(FADJECT);
 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, LOC_CARRIED);
 if (Parameter1 <> MAX_OBJECT) then
 begin
  _WEAR;
  exit;
 end;

 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, LOC_WORN);
 if (Parameter1 <> MAX_OBJECT) then
 begin
  _WEAR;
  exit;
 end;

 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, getFlag(FPLAYER));
 if (Parameter1 <> MAX_OBJECT) then
 begin
  _WEAR;
  exit;
 end;

 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, MAX_LOCATION); {Any Location}
 if (Parameter1 <> MAX_OBJECT) then Sysmess(SM28) {I don't have one of those.}
                               else Sysmess(SM8); {I can't do that.}
 newtext;
 _DONE;
end;

(*--------------------------------------------------------------------------------------*)
procedure _AUTOR;
var Noun, Adject : TFlagType;
begin
 Noun := getFlag(FNOUN);
 Adject := getFlag(FADJECT);
 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, LOC_WORN);
 if (Parameter1 <> MAX_OBJECT) then
 begin
  _REMOVE;
  exit;
 end;

 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, LOC_CARRIED);
 if (Parameter1 <> MAX_OBJECT) then
 begin
  _REMOVE;
  exit;
 end;

 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, getFlag(FPLAYER));
 if (Parameter1 <> MAX_OBJECT) then
 begin
  _REMOVE;
  exit;
 end;

 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, MAX_LOCATION); {Any Location}
 if (Parameter1 <> MAX_OBJECT) then Sysmess(SM23) {"I'm not wearing one of those.}
                               else Sysmess(SM8); {I can't do that.}
 newtext;
 _DONE;
 end;

(*--------------------------------------------------------------------------------------*)
procedure _PAUSE;
begin
 if (parameter1 = 0) then Delay(5.12)
                     else Delay(parameter1/50);
 done := true; 
end;

(*--------------------------------------------------------------------------------------*)
procedure _SYNONYM;
begin
 if (parameter1<>NO_WORD) then setFlag(FVERB, parameter1);
 if (parameter2<>NO_WORD) then setFlag(FNOUN, parameter1);
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _GOTO;
begin
 setFlag(FPLAYER, Parameter1);
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _MESSAGE;
begin
 _MES;
 _NEWLINE;
end;

(*--------------------------------------------------------------------------------------*)
procedure _REMOVE;
var ObjectLocation : TFlagType;
    WeightCarried, WeightWorn :  Word;
begin
 SetReferencedObject(parameter1);
 ObjectLocation :=getObjectLocation(parameter1);
 if (ObjectLocation = LOC_CARRIED) or (ObjectLocation=getFlag(FPLAYER)) then 
 begin
  Sysmess(SM50); {I'm not wearing the _.}
  newtext;
  _DONE;
  exit;
 end;

 if (ObjectLocation <> LOC_WORN) and (ObjectLocation<>getFlag(FPLAYER)) then 
 begin
  Sysmess(SM23);  {"I'm not wearing one of those.}
  newtext;
  _DONE;
  exit;
 end;

 if (not isObjectWearable(parameter1)) then
 begin
  Sysmess(SM41); {I can't remove the _.}
  newtext;
  _DONE;
  exit;
 end;

 if (getFlag(FPLAYER)>= getFlag(FOBJECTS_CONVEYABLE)) then
 begin
  Sysmess(SM42); {I can't remove the _. My hands are full.}
  newtext;
  _DONE;
  exit;
 end;
 setObjectLocation(parameter1, LOC_CARRIED);
 setFlag(FCARRIED, getFlag(FCARRIED) + 1);
 Sysmess(SM38); {I've removed the _.}
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _GET;
var ObjectLocation : TFlagType;
    WeightCarried, WeightWorn :  Word;
begin
 SetReferencedObject(parameter1);
 ObjectLocation :=getObjectLocation(parameter1);
 if (ObjectLocation = LOC_WORN) or (ObjectLocation=LOC_CARRIED) then 
 begin
  Sysmess(SM25); {I already have the_.}
  newtext;
  _DONE;
  exit;
 end;

 if (ObjectLocation <> getFlag(FPLAYER)) then 
 begin
  Sysmess(SM26); {There isn't one of those here.}
  newtext;
  _DONE;
  exit;
 end;

 WeightCarried := getObjectFullWeight(LOC_CARRIED);
 WeightWorn := getObjectFullWeight(LOC_WORN);
 if (WeightWorn + WeightCarried + getObjectFullWeight(parameter1) > getFlag(FPLAYER_STRENGTH)) then
 begin
  Sysmess(SM43); {The _ weighs too much for me.}
  newtext;
  _DONE;
  exit;
 end;

 if (getFlag(FCARRIED)>= getFlag(FOBJECTS_CONVEYABLE)) then
 begin
  Sysmess(SM27);  {I can't carry any more things.}
  DoallPTR := 0;
  newtext;
  _DONE;
  exit;
 end;

 setObjectLocation(parameter1, LOC_CARRIED);
 setFlag(FCARRIED, getFlag(FCARRIED) + 1);
 Sysmess(SM36); {I now have the _.}
 done := true;

end;

(*--------------------------------------------------------------------------------------*)
procedure _DROP;
var ObjectLocation : TFlagType;
begin
 SetReferencedObject(parameter1);
 ObjectLocation :=getObjectLocation(parameter1);
 if (ObjectLocation = LOC_WORN)  then 
 begin
  Sysmess(SM24); {I can't. I'm wearing the_.}
  newtext;
  _DONE;
  exit;
 end;

 if (ObjectLocation = getFlag(FPLAYER))  then 
 begin
  Sysmess(SM49); {I don't have the _.}
  newtext;
  _DONE;
  exit;
 end;

 if (ObjectLocation <> getFlag(FPLAYER)) and (ObjectLocation<>LOC_CARRIED)  then 
 begin
  Sysmess(SM28); {I don't have one of those.}
  newtext;
  _DONE;
  exit;
 end;

 setObjectLocation(parameter1, getFlag(FPLAYER));
 setFlag(FCARRIED, getFlag(FCARRIED) - 1);
 Sysmess(SM39); {I've dropped the _.}
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _WEAR;
var ObjectLocation : TFlagType;
begin
 SetReferencedObject(parameter1);
 ObjectLocation :=getObjectLocation(parameter1);
 if (ObjectLocation = getFlag(FPLAYER))  then 
 begin
  Sysmess(SM49); {I don't have the _.}
  newtext;
  _DONE;
  exit;
 end;

 if (ObjectLocation = LOC_WORN)  then 
 begin
  Sysmess(SM29); {I'm already wearing the _.}
  newtext;
  _DONE;
  exit;
 end;

 if (ObjectLocation <> LOC_CARRIED)  then 
 begin
  Sysmess(SM28); {I don't have one of those.}
  newtext;
  _DONE;
  exit;
 end;

 if (not isObjectWearable(parameter1)) then
begin
  Sysmess(SM40); {I can't wear the _.}
  newtext;
  _DONE;
  exit;
 end;

 setObjectLocation(parameter1, LOC_WORN);
 setFlag(FCARRIED, getFlag(FCARRIED) - 1);
 Sysmess(SM37); {I'm now wearing the _.}
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _DESTROY;
begin
  Parameter2 := LOC_NOT_CREATED;
 _PLACE;
end;

(*--------------------------------------------------------------------------------------*)
procedure _CREATE;
begin
 Parameter2 := getFlag(FPLAYER);
 _PLACE;
end;

(*--------------------------------------------------------------------------------------*)
procedure _SWAP;
var aux : TLocationType;
begin
 Aux := getObjectLocation(parameter1);
 setObjectLocation(parameter1, getObjectLocation(parameter2));
 setObjectLocation(parameter2, aux);
 SetReferencedObject(parameter2);
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _PLACE;
begin
 if (getObjectLocation(parameter1) = LOC_CARRIED) then setFlag(FCARRIED, getFlag(FCARRIED) - 1);
 setObjectLocation(parameter1, parameter2);
 if (getObjectLocation(parameter1) = LOC_CARRIED) then setFlag(FCARRIED, getFlag(FCARRIED) +1);
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _SET;
begin
 setFlag(Parameter1, MAX_FLAG_VALUE);
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _CLEAR;
begin
 setFlag(Parameter1, 0);
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _PLUS;
begin
 if getFlag(Parameter1) + Parameter2 > MAX_FLAG_VALUE then _SET
                                                      else setFlag(Parameter1, getFlag(Parameter1) + Parameter2);
 done := true;                                                      
end;

(*--------------------------------------------------------------------------------------*)
procedure _MINUS;
begin
 if getFlag(Parameter1) - Parameter2 <0  then _CLEAR
                                         else setFlag(parameter1, getFlag(Parameter1) - Parameter2);
 done := true;                                                        
end;

(*--------------------------------------------------------------------------------------*)
procedure _LET;
begin
 setFlag(Parameter1, parameter2);
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _NEWLINE;
begin
 CarriageReturn;
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _PRINT;
var value : TFlagtype;
    valstr : array[0..2] of char;
begin
 value := getFlag(parameter1);
 StrPCopy(valstr,inttostr(value));
 WriteText(valstr, false);
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _SYSMESS;
begin
 WriteText(getPcharMessage(DDBHeader.sysmessPos, parameter1), false);   
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _ISAT;
begin
    condactResult := getObjectLocation(Parameter1) = parameter2;
end;

(*--------------------------------------------------------------------------------------*)
procedure _SETCO;
begin
  SetReferencedObject(parameter1);
  done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _SPACE;
var Str: array[0..1] of char;
begin
    StrPCopy(Str, ' ');
    WriteText(Str, false);
    done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _HASAT;
var flag : TFlagType;
    bit : Word;
begin
    condactResult := getFlagBit(59-parameter1 div 8, parameter1 mod 8);
end;

(*--------------------------------------------------------------------------------------*)
procedure _HASNAT;
begin
    condactResult := not getFlagBit(59 - (parameter1 div 8), parameter1 mod 8);
end;

(*--------------------------------------------------------------------------------------*)
procedure _LISTOBJ;
begin
 listObjects(getFlag(FPLAYER), false);
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _EXTERN;
begin
(* FALTA CONDACTO EXTERN *)
done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _RAMSAVE;
begin
 RAMSaveFlags;
 RAMSaveObjects;
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _RAMLOAD;
begin
 RAMLoadFlags(parameter1);
 RAMLoadObjects;
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _BEEP;
begin
(* FALTA CONDACTO BEEP*)
done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _PAPER;
begin
 windows[ActiveWindow].PAPER := parameter1;
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _INK;
begin
 windows[ActiveWindow].INK := parameter1;
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _BORDER;
begin
 windows[ActiveWindow].BORDER := parameter1;
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _PREP;
begin
 condactResult := getFlag(FPREP) = parameter1;
end;

(*--------------------------------------------------------------------------------------*)
procedure _NOUN2;
begin
 condactResult := getFlag(FNOUN2) = parameter1;
end;

(*--------------------------------------------------------------------------------------*)
procedure _ADJECT2;
begin
 condactResult := getFlag(FADJECT2) = parameter1;
end;

(*--------------------------------------------------------------------------------------*)
procedure _ADD;
begin
 if getFlag(Parameter1) +  getFlag(Parameter2) > MAX_FLAG_VALUE then setFlag(Parameter2, MAX_FLAG_VALUE)
                                                     else setFlag(Parameter2, getFlag(Parameter1) + getFlag(Parameter2));
done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _SUB;
begin
 if getFlag(Parameter2) +  getFlag(Parameter1) <> 0 then setFlag(Parameter2, 0)
                                                    else setFlag(Parameter2, getFlag(Parameter2) + getFlag(Parameter1));
done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _PARSE;
var result : boolean;
begin
 result := parse(parameter1);
 if ((parameter1=0) and (result)) or (parameter1<>0) then condactResult := false;
 done := false;
 {(* FALTA DAR SOPORTE A PARSE 1*)}
end;

(*--------------------------------------------------------------------------------------*)
procedure _LISTAT;
begin
 listObjects(Parameter1, true);
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _PROCESS;
begin
    if (Parameter1 >= DDBHeader.numPro) then Error(3, 'Process ' + inttostr(parameter1) + 'does not exist');
    StackPush;
    DoallPTR := 0;
    DoallEntryPTR := 0; {Not really necessary}
    CondactPTR := 0;
    ProcessPTR :=  DDBHeader.processPos + 2 * parameter1;
    {As I really want to force a jump to first entry of this new   }
    {process I set the EntryPRT to 2 below the first entry and     }
    {make the condition fail, so actually we wil habe the EntryPTR }
    { increased by 2 on return and jump to entry validation        }
    EntryPTR :=  getWord(ProcessPTR) - 4;
    condactResult := false;
    {Done is cleared on exit, so ISDONE after a PROCESS call refers to the process and not to any previous execucition}
    Done := falsE;
end;

(*--------------------------------------------------------------------------------------*)
procedure _SAME;
begin
    condactResult := getFlag(Parameter1) = getFlag(parameter2);
end;

(*--------------------------------------------------------------------------------------*)
procedure _MES;
begin
  WriteText(getPcharMessage(DDBHeader.messagePos, parameter1), false);
  done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _WINDOW;
begin
 if (parameter1<NUM_WINDOWS) then
 begin
    ActiveWindow := parameter1;
    SetFlag(FACTIVEWINDOW, parameter1);
 end;
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _NOTEQ;
begin
    condactResult := getFlag(Parameter1) <> Parameter2;
end;

(*--------------------------------------------------------------------------------------*)
procedure _NOTSAME;
begin
    condactResult := getFlag(Parameter1) <> getFlag(parameter2);
end;

(*--------------------------------------------------------------------------------------*)
procedure _MODE;
begin
 Windows[ActiveWindow].OperationMode := parameter1;
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _WINAT;
begin
 Windows[ActiveWindow].line := parameter1;
 Windows[ActiveWindow].currentY := parameter1 * 8;
 Windows[ActiveWindow].col := parameter2;
 Windows[ActiveWindow].currentX := parameter2 * 8;
 ReconfigureWindow;
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _TIME;
begin
 SetFlag(FTIMEOUT, parameter1);
 SetFlag(FTIMEOUT_CONTROL, parameter2);
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _PICTURE;
begin
 condactResult := LoadPCX(Windows[ActiveWindow].col * 8, Windows[ActiveWindow].line * 8,
                  Windows[ActiveWindow].width * 8, Windows[ActiveWindow].height * 8,
                  parameter1);
 (* FALTA: PICTURE apparenty only loads the picture to a buffer, it's DISPLAY the one painting the picture
   so I guess this will be all about loading the picture to some kind of buffer, or actually to just set
   the buffer to the filename value to simulate there is a buffer. Today, for hard disk based games this is
   actually irrelevant *)
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _DOALL;
var objno: TFlagType;
begin
 DoallPTR := CondactPTR + 1; {Point to next Condact after DOALL}
 DoallEntryPTR := EntryPTR;
 DoallLocation := parameter1;
 objno := getNextObjectAt(-1, parameter1);
 SetFlag(FDOALL,objno);
 SetReferencedObject(objno);
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _MOUSE;
begin
(* FALTA CONDACTO MOUSE *)
done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _GFX;
begin
(* FALTA CONDACTO GFX *)
done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _ISNOTAT;
begin
    condactResult := getObjectLocation(Parameter1) <> parameter2;
end;

(*--------------------------------------------------------------------------------------*)
procedure _WEIGH;
begin
 Setflag(parameter2, getObjectFullWeight(parameter1));
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _PUTIN;
var ObjectLocation : TFlagType;
    WeightCarried, WeightWorn :  Word;
begin
 SetReferencedObject(parameter1);
 ObjectLocation :=getObjectLocation(parameter1);
 if (ObjectLocation = LOC_WORN) then 
 begin
  Sysmess(SM24); {I can't. I'm wearing the_.}
  newtext;
  _DONE;
  exit;
 end;

 if (ObjectLocation = getFlag(FPLAYER)) then 
 begin
  Sysmess(SM49); {I don't have the _.}
  newtext;
  _DONE;
  exit;
 end;

if (ObjectLocation <> getFlag(FPLAYER)) and (ObjectLocation <> LOC_CARRIED) then 
 begin
  Sysmess(SM28); {I don't have one of those.}
  newtext;
  _DONE;
  exit;
 end;

 setObjectLocation(parameter1, parameter2);
 setFlag(FCARRIED, getFlag(FCARRIED) - 1);
 Sysmess(SM44); {The _ is in the }
 WriteText(getPcharMessage(DDBHeader.objectPos, parameter2), false);
 Sysmess(SM51); {.}
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _NEWTEXT;
begin
    newtext;
    done := true;
end;


(*--------------------------------------------------------------------------------------*)
procedure _TAKEOUT;
var ObjectLocation : TFlagType;
    WeightCarried, WeightWorn :  Word;
begin
 SetReferencedObject(parameter1);
 ObjectLocation :=getObjectLocation(parameter1);
 if (ObjectLocation = LOC_WORN) or (ObjectLocation=LOC_CARRIED) then 
 begin
  Sysmess(SM45); {I already have the _.}
  newtext;
  _DONE;
  exit;
 end;

 if (ObjectLocation = getFlag(FPLAYER)) then 
 begin
  Sysmess(SM49); {The _ isn't in the}
  WriteText(getPcharMessage(DDBHeader.objectPos, parameter2), false);
  Sysmess(SM51);{.}
  newtext;
  _DONE;
  exit;
 end;

if (ObjectLocation <> getFlag(FPLAYER)) and (ObjectLocation <> parameter2) then 
 begin
  Sysmess(SM52); {There isn't one of those in the}
  WriteText(getPcharMessage(DDBHeader.objectPos, parameter2), false);
  Sysmess(SM51);{.}
  newtext;
  _DONE;
  exit;
 end;

if (ObjectLocation <> LOC_CARRIED) and (ObjectLocation <> LOC_WORN) then 
begin
 WeightCarried := getObjectFullWeight(LOC_CARRIED);
 WeightWorn := getObjectFullWeight(LOC_WORN);
 if (WeightCarried + WeightWorn + getObjectFullWeight(parameter1) > getFlag(FPLAYER_STRENGTH)) then
 begin
   Sysmess(SM43); {The _ weighs too much for me.}
   newtext;
   _DONE;
   exit;
 end;
end; 

if (GetFlag(FCARRIED) >=  GetFlag(FOBJECTS_CONVEYABLE)) then
 begin
  Sysmess(SM27); {"I can't carry any more things.}
  newtext;
  DoallPTR := 0;
  _DONE;
  exit;
 end;

 setObjectLocation(parameter1, LOC_CARRIED);
 setFlag(FCARRIED, getFlag(FCARRIED) + 1);
 Sysmess(SM36); {I now have the _.}
 done := true;
end;


(*--------------------------------------------------------------------------------------*)
procedure _ABILITY;
begin
 setFlag(FOBJECTS_CONVEYABLE, Parameter1);
 setFlag(FPLAYER_STRENGTH, Parameter2);
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _WEIGHT;
var i, w, w2 : word;
    l : TLocationType;
begin
  w := 0;
  for i:=0  to DDBHeader.numObj - 1 do 
  begin
   l := getObjectLocation(i);
   if (l=LOC_CARRIED) or (l=LOC_WORN) then
   begin
    w2 := getObjectFullWeight(i);
    if (w + w2 > high(TFlagType)) then w:=high(TFlagType)
                                  else w := w + w2;
   end
  end; 
  Setflag(parameter1, w);
  done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _RANDOM;
begin
 SetFlag(parameter1, random(101));
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _INPUT;
begin
(* FALTA CONDACTO INPUT *)
done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _SAVEAT;
begin
  SaveAt;
  done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _BACKAT;
begin
  BackAt;
  done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _PRINTAT;
begin
  Printat(parameter1, parameter2);
  done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _WHATO;
var currentNoun, currentAdjective : TFlagType;
    objno : TFlagtype;
begin
 currentNoun := getFlag(FNOUN);
 currentAdjective := getFlag(FVERB);
 objno := getObjectByVocabularyAtLocation(currentNoun, currentAdjective, LOC_CARRIED);
 if (objno <> NO_OBJECT) then SetReferencedObject(objno)
 else 
 begin
   objno := getObjectByVocabularyAtLocation(currentNoun, currentAdjective, LOC_WORN);
   if (objno <> NO_OBJECT) then SetReferencedObject(objno)
   else
   begin
    objno := getObjectByVocabularyAtLocation(currentNoun, currentAdjective, getFlag(FPLAYER));
    if (objno <> NO_OBJECT) then SetReferencedObject(objno)
    else
    begin
        {Despite what documentation says, DAAD performs a search at ANY location if object not present }
        { getObjectByVocabularyAtLocation searchs at any location if location = MAX_LOCATION}
        objno := getObjectByVocabularyAtLocation(currentNoun, currentAdjective, MAX_LOCATION);
        if (objno <> NO_OBJECT) then SetReferencedObject(objno)
        else SetReferencedObject(MAX_LOCATION);
    end
   end;
 end;
 done := true;
end; 

(*--------------------------------------------------------------------------------------*)
procedure _CALL;
begin
(* FALTA CONDACTO CALL *)
done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _PUTO;
begin
 parameter2 := parameter1;
 parameter1 := getFlag(FREFOBJ);
 _PLACE;
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _NOTDONE;
begin
 done := false;
 ConsumeProcess; {Go to last entry}
 {force failure so we jump to next entry, which happens to be the mark of end of process}
 condactResult := false; 
end;

(*--------------------------------------------------------------------------------------*)
procedure _AUTOP;
var Noun, Adject : TFlagType;
begin
 Parameter2 := Parameter1; {To use it with PUTIN}
 Noun := getFlag(FNOUN);
 Adject := getFlag(FADJECT);
 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, LOC_CARRIED);
 if (Parameter1 <> MAX_OBJECT) then
 begin
  _PUTIN;
  exit;
 end;

 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, LOC_WORN);
 if (Parameter1 <> MAX_OBJECT) then
 begin
  _PUTIN;
  exit;
 end;

 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, getFlag(FPLAYER));
 if (Parameter1 <> MAX_OBJECT) then
 begin
  _PUTIN;
  exit;
 end;

 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, MAX_LOCATION); {Any Location}
 if (Parameter1 <> MAX_OBJECT) then Sysmess(SM28) {I don't have one of those.}
                               else Sysmess(SM8); {I can't do that.}
 newtext;
 _DONE;
end;

(*--------------------------------------------------------------------------------------*)
procedure _AUTOT;
var Noun, Adject : TFlagType;
begin
 Parameter2 := Parameter1; {To use it with PUTIN}
 Noun := getFlag(FNOUN);
 Adject := getFlag(FADJECT);

 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, parameter2); {In container}
 if (Parameter1 <> MAX_OBJECT) then
 begin
  _TAKEOUT;
  exit;
 end;


 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, LOC_CARRIED);
 if (Parameter1 <> MAX_OBJECT) then
 begin
  _TAKEOUT;
  exit;
 end;

 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, LOC_WORN);
 if (Parameter1 <> MAX_OBJECT) then
 begin
  _TAKEOUT;
  exit;
 end;

 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, getFlag(FPLAYER));
 if (Parameter1 <> MAX_OBJECT) then
 begin
  _TAKEOUT;
  exit;
 end;

 Parameter1 := getObjectByVocabularyAtLocation(Noun, Adject, MAX_LOCATION); {Any Location}
 if (Parameter1 <> MAX_OBJECT) then begin
                                     Sysmess(SM52); {There isn't one of those in the}
                                     WriteText(getPcharMessage(DDBHeader.objectPos, parameter2), false);
                                     Sysmess(SM51); {. }
                                    end
                               else Sysmess(SM8); {I can't do that.}
 newtext;
 _DONE;
end;

(*--------------------------------------------------------------------------------------*)
procedure _MOVE;
var Ptr : Word;
    Direction : TFlagType;
begin
 Ptr := GetWord(DDBHeader.connectionPos + 2 * getFlag(parameter1));
 repeat
  Direction := GetByte(Ptr);
  if (Direction<>END_OF_CONNECTIONS_MARK) and (Direction = getFlag(FVERB)) then 
  begin
   setFlag(parameter1, GetByte(Ptr+1));
   exit;
  end; 
  Ptr := Ptr + 2;
 until Direction = END_OF_CONNECTIONS_MARK;
 condactResult := false; {If no movement, condition fails}
 end;

(*--------------------------------------------------------------------------------------*)
procedure _WINSIZE;
begin
 Windows[ActiveWindow].height := parameter1;
 Windows[ActiveWindow].width := parameter2;
 ReconfigureWindow;
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _REDO;
begin
  {Point two bytes below first entry because on return the engine will add 4}
  EntryPTR := getWord(ProcessPTR) - 4; 
  condactResult := false;  {force so we get out of current entry and the jump to first entry}
end;

(*--------------------------------------------------------------------------------------*)
procedure _CENTRE;
begin
(* FALTA CONDACTO CENTRE *)
end;

(*--------------------------------------------------------------------------------------*)
procedure _EXIT;
begin
 if (parameter1 = 0) then 
 begin
  terminateVideoMode;
  halt(0);
 end; 
 resetWindows;
 resetFlags;
 resetObjects;
 _RESTART;
end;

(*--------------------------------------------------------------------------------------*)
procedure _INKEY;
var inkey : word;
begin
  if Keypressed then inkey := ReadKey else inkey := 0;
  setflag(FKEY1, inkey and $FF);
  setflag(FKEY1, (inkey and $FF00) SHR 8);
  done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _BIGGER;
begin
 condactResult := getFlag(Parameter1) > getFlag(Parameter2);
end;

(*--------------------------------------------------------------------------------------*)
procedure _SMALLER;
begin
 condactResult := getFlag(Parameter1) < getFlag(Parameter2);
end;

(*--------------------------------------------------------------------------------------*)
procedure _ISDONE;
begin
 condactResult := done;
end;

(*--------------------------------------------------------------------------------------*)
procedure _ISNDONE;
begin
 condactResult := not done;
end;

(*--------------------------------------------------------------------------------------*)
procedure _SKIP;
var OriginalSkip: integer;
begin
 OriginalSkip := parameter1 - 256; {Bring back the -128 to 127 value}
 EntryPTR := EntryPtr + 4 * OriginalSkip; 
 condactResult := false;
end;

(*--------------------------------------------------------------------------------------*)
procedure _RESTART;
begin
 {Reset the stack and the processes to go back to process 0}
 resetProcesses;
 resetStack;
 {When we force condact to fail, it will inrease EntryPTR by 4 and continue execution}
 {So we first make EntryPTR point two point below}
 EntryPTR := getWord(ProcessPtr)  -4;
 condactResult := false;
 end;

(*--------------------------------------------------------------------------------------*)
procedure _TAB;
begin
 Tab(parameter1);
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _COPYOF;
begin
 setFlag(parameter2, getObjectLocation(parameter1));
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _COPYOO;
var aux: TFlagType;
begin
 {Its like placing objno2 at objno1 location}
 aux := parameter2;
 Parameter2 := getObjectLocation(parameter1);
 Parameter1 := aux;
 _PLACE;
end;

(*--------------------------------------------------------------------------------------*)
procedure _COPYFO;
var aux: TFlagType;
begin
 {Its like placing objno2 at flagno1}
 aux := parameter2;
 Parameter2 := getFlag(parameter1);
 Parameter1 := aux;
 _PLACE;
end;

(*--------------------------------------------------------------------------------------*)
procedure _dumb;
begin
end;

(*--------------------------------------------------------------------------------------*)
procedure _COPYFF;
begin
 SetFlag(Parameter2, getFlag(Parameter1));
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _COPYBF;
begin
 SetFlag(Parameter1, getFlag(Parameter2));
 done := true;
end;

(*--------------------------------------------------------------------------------------*)
procedure _RESET;
begin
 resetObjects;
 done := true;
end;



end.
