{$I SETTINGS.INC}
(* All the condacts stuff, including implementation of condacts *)

unit condacts;

interface

uses global;

const MAX_CONDACTS = 128;

type TCondactType = record
                        {$ifdef DEBUG}
                        condactName : String;
                        {$endif}
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
({$ifdef DEBUG}condactName: 'AT     '; {$endif}condactRoutine: _AT     ; numParams: 1), {   0 $00}
({$ifdef DEBUG}condactName: 'NOTAT  '; {$endif}condactRoutine: _NOTAT  ; numParams: 1), {   1 $01}
({$ifdef DEBUG}condactName: 'ATGT   '; {$endif}condactRoutine: _ATGT   ; numParams: 1), {   2 $$02}
({$ifdef DEBUG}condactName: 'ATLT   '; {$endif}condactRoutine: _ATLT   ; numParams: 1), {   3 $03}
({$ifdef DEBUG}condactName: 'PRESENT'; {$endif}condactRoutine: _PRESENT; numParams: 1), {   4 $04}
({$ifdef DEBUG}condactName: 'ABSENT '; {$endif}condactRoutine: _ABSENT ; numParams: 1), {   5 $05}
({$ifdef DEBUG}condactName: 'WORN   '; {$endif}condactRoutine: _WORN   ; numParams: 1), {   6 $06}
({$ifdef DEBUG}condactName: 'NOTWORN'; {$endif}condactRoutine: _NOTWORN; numParams: 1), {   7 $07}
({$ifdef DEBUG}condactName: 'CARRIED'; {$endif}condactRoutine: _CARRIED; numParams: 1), {   8 $08}
({$ifdef DEBUG}condactName: 'NOTCARR'; {$endif}condactRoutine: _NOTCARR; numParams: 1), {   9 $09}
({$ifdef DEBUG}condactName: 'CHANCE '; {$endif}condactRoutine: _CHANCE ; numParams: 1), {  10 $0A}
({$ifdef DEBUG}condactName: 'ZERO   '; {$endif}condactRoutine: _ZERO   ; numParams: 1), {  11 $0B}
({$ifdef DEBUG}condactName: 'NOTZERO'; {$endif}condactRoutine: _NOTZERO; numParams: 1), {  12 $0C}
({$ifdef DEBUG}condactName: 'EQ     '; {$endif}condactRoutine: _EQ     ; numParams: 2), {  13 $0D}
({$ifdef DEBUG}condactName: 'GT     '; {$endif}condactRoutine: _GT     ; numParams: 2), {  14 $0E}
({$ifdef DEBUG}condactName: 'LT     '; {$endif}condactRoutine: _LT     ; numParams: 2), {  15 $0F}
({$ifdef DEBUG}condactName: 'ADJECT1'; {$endif}condactRoutine: _ADJECT1; numParams: 1), {  16 $10}
({$ifdef DEBUG}condactName: 'ADVERB '; {$endif}condactRoutine: _ADVERB ; numParams: 1), {  17 $11}
({$ifdef DEBUG}condactName: 'SFX    '; {$endif}condactRoutine: _SFX    ; numParams: 2), {  18 $12}
({$ifdef DEBUG}condactName: 'DESC   '; {$endif}condactRoutine: _DESC   ; numParams: 1), {  19 $13}
({$ifdef DEBUG}condactName: 'QUIT   '; {$endif}condactRoutine: _QUIT   ; numParams: 0), {  20 $14}
({$ifdef DEBUG}condactName: 'END    '; {$endif}condactRoutine: _END    ; numParams: 0), {  21 $15}
({$ifdef DEBUG}condactName: 'DONE   '; {$endif}condactRoutine: _DONE   ; numParams: 0), {  22 $16}
({$ifdef DEBUG}condactName: 'OK     '; {$endif}condactRoutine: _OK     ; numParams: 0), {  23 $17}
({$ifdef DEBUG}condactName: 'ANYKEY '; {$endif}condactRoutine: _ANYKEY ; numParams: 0), {  24 $18}
({$ifdef DEBUG}condactName: 'SAVE   '; {$endif}condactRoutine: _SAVE   ; numParams: 1), {  25 $19}
({$ifdef DEBUG}condactName: 'LOAD   '; {$endif}condactRoutine: _LOAD   ; numParams: 1), {  26 $1A}
({$ifdef DEBUG}condactName: 'DPRINT '; {$endif}condactRoutine: _DPRINT ; numParams: 1), {  27 $1B}
({$ifdef DEBUG}condactName: 'DISPLAY'; {$endif}condactRoutine: _DISPLAY; numParams: 1), {  28 $1C}
({$ifdef DEBUG}condactName: 'CLS    '; {$endif}condactRoutine: _CLS    ; numParams: 0), {  29 $1D}
({$ifdef DEBUG}condactName: 'DROPALL'; {$endif}condactRoutine: _DROPALL; numParams: 0), {  30 $1E}
({$ifdef DEBUG}condactName: 'AUTOG  '; {$endif}condactRoutine: _AUTOG  ; numParams: 0), {  31 $1F}
({$ifdef DEBUG}condactName: 'AUTOD  '; {$endif}condactRoutine: _AUTOD  ; numParams: 0), {  32 $20}
({$ifdef DEBUG}condactName: 'AUTOW  '; {$endif}condactRoutine: _AUTOW  ; numParams: 0), {  33 $21}
({$ifdef DEBUG}condactName: 'AUTOR  '; {$endif}condactRoutine: _AUTOR  ; numParams: 0), {  34 $22}
({$ifdef DEBUG}condactName: 'PAUSE  '; {$endif}condactRoutine: _PAUSE  ; numParams: 1), {  35 $23}
({$ifdef DEBUG}condactName: 'SYNONYM'; {$endif}condactRoutine: _SYNONYM; numParams: 2), {  36 $24}
({$ifdef DEBUG}condactName: 'GOTO   '; {$endif}condactRoutine: _GOTO   ; numParams: 1), {  37 $25}
({$ifdef DEBUG}condactName: 'MESSAGE'; {$endif}condactRoutine: _MESSAGE; numParams: 1), {  38 $26}
({$ifdef DEBUG}condactName: 'REMOVE '; {$endif}condactRoutine: _REMOVE ; numParams: 1), {  39 $27}
({$ifdef DEBUG}condactName: 'GET    '; {$endif}condactRoutine: _GET    ; numParams: 1), {  40 $28}
({$ifdef DEBUG}condactName: 'DROP   '; {$endif}condactRoutine: _DROP   ; numParams: 1), {  41 $29}
({$ifdef DEBUG}condactName: 'WEAR   '; {$endif}condactRoutine: _WEAR   ; numParams: 1), {  42 $2A}
({$ifdef DEBUG}condactName: 'DESTROY'; {$endif}condactRoutine: _DESTROY; numParams: 1), {  43 $2B}
({$ifdef DEBUG}condactName: 'CREATE '; {$endif}condactRoutine: _CREATE ; numParams: 1), {  44 $2C}
({$ifdef DEBUG}condactName: 'SWAP   '; {$endif}condactRoutine: _SWAP   ; numParams: 2), {  45 $2D}
({$ifdef DEBUG}condactName: 'PLACE  '; {$endif}condactRoutine: _PLACE  ; numParams: 2), {  46 $2E}
({$ifdef DEBUG}condactName: 'SET    '; {$endif}condactRoutine: _SET    ; numParams: 1), {  47 $2F}
({$ifdef DEBUG}condactName: 'CLEAR  '; {$endif}condactRoutine: _CLEAR  ; numParams: 1), {  48 $30}
({$ifdef DEBUG}condactName: 'PLUS   '; {$endif}condactRoutine: _PLUS   ; numParams: 2), {  49 $31}
({$ifdef DEBUG}condactName: 'MINUS  '; {$endif}condactRoutine: _MINUS  ; numParams: 2), {  50 $32}
({$ifdef DEBUG}condactName: 'LET    '; {$endif}condactRoutine: _LET    ; numParams: 2), {  51 $33}
({$ifdef DEBUG}condactName: 'NEWLINE'; {$endif}condactRoutine: _NEWLINE; numParams: 0), {  52 $34}
({$ifdef DEBUG}condactName: 'PRINT  '; {$endif}condactRoutine: _PRINT  ; numParams: 1), {  53 $35}
({$ifdef DEBUG}condactName: 'SYSMESS'; {$endif}condactRoutine: _SYSMESS; numParams: 1), {  54 $36}
({$ifdef DEBUG}condactName: 'ISAT   '; {$endif}condactRoutine: _ISAT   ; numParams: 2), {  55 $37}
({$ifdef DEBUG}condactName: 'SETCO  '; {$endif}condactRoutine: _SETCO  ; numParams: 1), {  56 $38}
({$ifdef DEBUG}condactName: 'SPACE  '; {$endif}condactRoutine: _SPACE  ; numParams: 1), {  57 $39}
({$ifdef DEBUG}condactName: 'HASAT  '; {$endif}condactRoutine: _HASAT  ; numParams: 1), {  58 $3A}
({$ifdef DEBUG}condactName: 'HASNAT '; {$endif}condactRoutine: _HASNAT ; numParams: 1), {  59 $3B}
({$ifdef DEBUG}condactName: 'LISTOBJ'; {$endif}condactRoutine: _LISTOBJ; numParams: 0), {  60 $3C}
({$ifdef DEBUG}condactName: 'EXTERN '; {$endif}condactRoutine: _EXTERN ; numParams: 2), {  61 $3D}
({$ifdef DEBUG}condactName: 'RAMSAVE'; {$endif}condactRoutine: _RAMSAVE; numParams: 0), {  62 $3E}
({$ifdef DEBUG}condactName: 'RAMLOAD'; {$endif}condactRoutine: _RAMLOAD; numParams: 1), {  63 $3F}
({$ifdef DEBUG}condactName: 'BEEP   '; {$endif}condactRoutine: _BEEP   ; numParams: 2), {  64 $40}
({$ifdef DEBUG}condactName: 'PAPER  '; {$endif}condactRoutine: _PAPER  ; numParams: 1), {  65 $41}
({$ifdef DEBUG}condactName: 'INK    '; {$endif}condactRoutine: _INK    ; numParams: 1), {  66 $42}
({$ifdef DEBUG}condactName: 'BORDER '; {$endif}condactRoutine: _BORDER ; numParams: 1), {  67 $43}
({$ifdef DEBUG}condactName: 'PREP   '; {$endif}condactRoutine: _PREP   ; numParams: 1), {  68 $44}
({$ifdef DEBUG}condactName: 'NOUN2  '; {$endif}condactRoutine: _NOUN2  ; numParams: 1), {  69 $45}
({$ifdef DEBUG}condactName: 'ADJECT2'; {$endif}condactRoutine: _ADJECT2; numParams: 1), {  70 $46}
({$ifdef DEBUG}condactName: 'ADD    '; {$endif}condactRoutine: _ADD    ; numParams: 2), {  71 $47}
({$ifdef DEBUG}condactName: 'SUB    '; {$endif}condactRoutine: _SUB    ; numParams: 2), {  72 $48}
({$ifdef DEBUG}condactName: 'PARSE  '; {$endif}condactRoutine: _PARSE  ; numParams: 1), {  73 $49}
({$ifdef DEBUG}condactName: 'LISTAT '; {$endif}condactRoutine: _LISTAT ; numParams: 1), {  74 $4A}
({$ifdef DEBUG}condactName: 'PROCESS'; {$endif}condactRoutine: _PROCESS; numParams: 1), {  75 $4B}
({$ifdef DEBUG}condactName: 'SAME   '; {$endif}condactRoutine: _SAME   ; numParams: 2), {  76 $4C}
({$ifdef DEBUG}condactName: 'MES    '; {$endif}condactRoutine: _MES    ; numParams: 1), {  77 $4D}
({$ifdef DEBUG}condactName: 'WINDOW '; {$endif}condactRoutine: _WINDOW ; numParams: 1), {  78 $4E}
({$ifdef DEBUG}condactName: 'NOTEQ  '; {$endif}condactRoutine: _NOTEQ  ; numParams: 2), {  79 $4F}
({$ifdef DEBUG}condactName: 'NOTSAME'; {$endif}condactRoutine: _NOTSAME; numParams: 2), {  80 $50}
({$ifdef DEBUG}condactName: 'MODE   '; {$endif}condactRoutine: _MODE   ; numParams: 1), {  81 $51}
({$ifdef DEBUG}condactName: 'WINAT  '; {$endif}condactRoutine: _WINAT  ; numParams: 2), {  82 $52}
({$ifdef DEBUG}condactName: 'TIME   '; {$endif}condactRoutine: _TIME   ; numParams: 2), {  83 $53}
({$ifdef DEBUG}condactName: 'PICTURE'; {$endif}condactRoutine: _PICTURE; numParams: 1), {  84 $54}
({$ifdef DEBUG}condactName: 'DOALL  '; {$endif}condactRoutine: _DOALL  ; numParams: 1), {  85 $55}
({$ifdef DEBUG}condactName: 'MOUSE  '; {$endif}condactRoutine: _MOUSE  ; numParams: 1), {  86 $56}
({$ifdef DEBUG}condactName: 'GFX    '; {$endif}condactRoutine: _GFX    ; numParams: 2), {  87 $57}
({$ifdef DEBUG}condactName: 'ISNOTAT'; {$endif}condactRoutine: _ISNOTAT; numParams: 2), {  88 $58}
({$ifdef DEBUG}condactName: 'WEIGH  '; {$endif}condactRoutine: _WEIGH  ; numParams: 2), {  89 $59}
({$ifdef DEBUG}condactName: 'PUTIN  '; {$endif}condactRoutine: _PUTIN  ; numParams: 2), {  90 $5A}
({$ifdef DEBUG}condactName: 'TAKEOUT'; {$endif}condactRoutine: _TAKEOUT; numParams: 2), {  91 $5B}
({$ifdef DEBUG}condactName: 'NEWTEXT'; {$endif}condactRoutine: _NEWTEXT; numParams: 0), {  92 $5C}
({$ifdef DEBUG}condactName: 'ABILITY'; {$endif}condactRoutine: _ABILITY; numParams: 2), {  93 $5D}
({$ifdef DEBUG}condactName: 'WEIGHT '; {$endif}condactRoutine: _WEIGHT ; numParams: 1), {  94 $5E}
({$ifdef DEBUG}condactName: 'RANDOM '; {$endif}condactRoutine: _RANDOM ; numParams: 1), {  95 $5F}
({$ifdef DEBUG}condactName: 'INPUT  '; {$endif}condactRoutine: _INPUT  ; numParams:21), {  96 $60}
({$ifdef DEBUG}condactName: 'SAVEAT '; {$endif}condactRoutine: _SAVEAT ; numParams: 0), {  97 $61}
({$ifdef DEBUG}condactName: 'BACKAT '; {$endif}condactRoutine: _BACKAT ; numParams: 0), {  98 $62}
({$ifdef DEBUG}condactName: 'PRINTAT'; {$endif}condactRoutine: _PRINTAT; numParams: 2), {  99 $63}
({$ifdef DEBUG}condactName: 'WHATO  '; {$endif}condactRoutine: _WHATO  ; numParams: 0), { 100 $64}
({$ifdef DEBUG}condactName: 'CALL   '; {$endif}condactRoutine: _CALL   ; numParams: 1), { 101 $65}
({$ifdef DEBUG}condactName: 'PUTO   '; {$endif}condactRoutine: _PUTO   ; numParams: 1), { 102 $66}
({$ifdef DEBUG}condactName: 'NOTDONE'; {$endif}condactRoutine: _NOTDONE; numParams: 0), { 103 $67}
({$ifdef DEBUG}condactName: 'AUTOP  '; {$endif}condactRoutine: _AUTOP  ; numParams: 1), { 104 $68}
({$ifdef DEBUG}condactName: 'AUTOT  '; {$endif}condactRoutine: _AUTOT  ; numParams: 1), { 105 $69}
({$ifdef DEBUG}condactName: 'MOVE   '; {$endif}condactRoutine: _MOVE   ; numParams: 1), { 106 $6A}
({$ifdef DEBUG}condactName: 'WINSIZE'; {$endif}condactRoutine: _WINSIZE; numParams: 2), { 107 $6B}
({$ifdef DEBUG}condactName: 'REDO   '; {$endif}condactRoutine: _REDO   ; numParams: 0), { 108 $6C}
({$ifdef DEBUG}condactName: 'CENTRE '; {$endif}condactRoutine: _CENTRE ; numParams: 0), { 109 $6D}
({$ifdef DEBUG}condactName: 'EXIT   '; {$endif}condactRoutine: _EXIT   ; numParams: 1), { 110 $6E}
({$ifdef DEBUG}condactName: 'INKEY  '; {$endif}condactRoutine: _INKEY  ; numParams: 0), { 111 $6F}
({$ifdef DEBUG}condactName: 'BIGGER '; {$endif}condactRoutine: _BIGGER ; numParams: 2), { 112 $70}
({$ifdef DEBUG}condactName: 'SMALLER'; {$endif}condactRoutine: _SMALLER; numParams: 2), { 113 $71}
({$ifdef DEBUG}condactName: 'ISDONE '; {$endif}condactRoutine: _ISDONE ; numParams: 0), { 114 $72}
({$ifdef DEBUG}condactName: 'ISNDONE'; {$endif}condactRoutine: _ISNDONE; numParams: 0), { 115 $73}
({$ifdef DEBUG}condactName: 'SKIP   '; {$endif}condactRoutine: _SKIP   ; numParams: 1), { 116 $74}
({$ifdef DEBUG}condactName: 'RESTART'; {$endif}condactRoutine: _RESTART; numParams: 0), { 117 $75}
({$ifdef DEBUG}condactName: 'TAB    '; {$endif}condactRoutine: _TAB    ; numParams: 1), { 118 $76}
({$ifdef DEBUG}condactName: 'COPYOF '; {$endif}condactRoutine: _COPYOF ; numParams: 2), { 119 $77}
({$ifdef DEBUG}condactName: 'dumb   '; {$endif}condactRoutine: _dumb   ; numParams: 0), { 120 $78}
({$ifdef DEBUG}condactName: 'COPYOO '; {$endif}condactRoutine: _COPYOO ; numParams: 2), { 121 $79}
({$ifdef DEBUG}condactName: 'dumb   '; {$endif}condactRoutine: _dumb   ; numParams: 0), { 122 $7A}
({$ifdef DEBUG}condactName: 'COPYFO '; {$endif}condactRoutine: _COPYFO ; numParams: 2), { 123 $7B}
({$ifdef DEBUG}condactName: 'dumb   '; {$endif}condactRoutine: _dumb   ; numParams: 0), { 124 $7C}
({$ifdef DEBUG}condactName: 'COPYFF '; {$endif}condactRoutine: _COPYFF ; numParams: 2), { 125 $7D}
({$ifdef DEBUG}condactName: 'COPYBF '; {$endif}condactRoutine: _COPYBF ; numParams: 2), { 126 $7E}
({$ifdef DEBUG}condactName: 'RESET  '; {$endif}condactRoutine: _RESET  ; numParams: 0)  { 127 $7F}
);

implementation



uses flags, ddb, objects, ibmpc, stack, messages, strings, errors, utils, parser;


procedure _AT;
begin
    condactResult := getFlag(FPLAYER) = Parameter1;
end;

procedure _NOTAT;
begin
    condactResult := getFlag(FPLAYER) <> Parameter1;
end;

procedure _ATGT;
begin
    condactResult := getFlag(FPLAYER) > Parameter1;
end;

procedure _ATLT;
begin
    condactResult := getFlag(FPLAYER) < Parameter1;
end;

procedure _PRESENT;
var objectLocation : TLocationType;
begin
    objectLocation := getObjectLocation(parameter1);
    condactResult := (objectLocation = LOC_CARRIED) or (objectLocation = LOC_WORN) or (objectLocation = getFlag(FPLAYER)) ;
end;

procedure _ABSENT;
var objectLocation : TLocationType;
begin
    objectLocation := getObjectLocation(parameter1);
    condactResult := (objectLocation <> LOC_CARRIED) 
                       and (objectLocation <> LOC_WORN) 
                         and (objectLocation <> getFlag(FPLAYER)) ;
end;

procedure _WORN;
begin
    condactResult := getObjectLocation(parameter1) = LOC_WORN;
end;

procedure _NOTWORN;
begin
    condactResult := getObjectLocation(parameter1) <> LOC_WORN;
end;

procedure _CARRIED;
begin
    condactResult := getObjectLocation(parameter1) = LOC_CARRIED;
end;

procedure _NOTCARR;
begin
    condactResult := getObjectLocation(parameter1) <> LOC_CARRIED;
end;

procedure _CHANCE;
begin
 if (parameter1 > 100) then condactResult := false
                       else condactResult :=  random(101) <= parameter1;
end;

procedure _ZERO;
begin
    condactResult := getFlag(Parameter1) = 0;
end;

procedure _NOTZERO;
begin
    condactResult := getFlag(Parameter1) <> 0;
end;

procedure _EQ;
begin
    condactResult := getFlag(Parameter1) = Parameter2;
end;

procedure _GT;
begin
    condactResult := getFlag(Parameter1) > Parameter2;
end;

procedure _LT;
begin
    condactResult := getFlag(Parameter1) < Parameter2;
end;

procedure _ADJECT1;
begin
 condactResult := getFlag(FADJECT) = parameter1;
end;

procedure _ADVERB;
begin
 condactResult := getFlag(FADVERB) = parameter1;
end;

procedure _SFX;
begin
(* FALTA *)
 done := true;
end;

procedure _DESC;
begin
  WriteText(getPcharMessage(DDBHeader.locationPos, parameter1));
  done := true;
end;

procedure _QUIT;
begin
(* FALTA *)
end;

procedure _END;
begin
(* FALTA *)
end;

procedure _DONE;
begin
 done := true;
 ConsumeProcess; {Go to last entry}
 {force failure so we jump to next entry, which happens to be the mark of end of process}
 condactResult := false; 
end;

procedure _OK;
begin
 Parameter1 := SYSMESS15; {"OK"}
 _SYSMESS;
 _DONE;
end;

procedure _ANYKEY;
begin
 while getKey = 0 do;
 done := true; 
 (* FALTA SOPORTE DE TIMEOUT EN ANYKEY *)
end;

procedure _SAVE;
begin
    { Hay que grabar los flags, las localidades de los obejtos, la configuración de
     ventanas (cada una con sus datos, y cual es la activa), y seguramente algunas
     otras variables como la direccion de doall y no sé si algo más. PENSAR. }
    (* FALTA *)
    done := true;
end;

procedure _LOAD;
begin
(* FALTA *)
done := true;
end;

procedure _DPRINT;
var value: Word;
begin
    Value := getFlag(parameter1) + 256 * getFlag(parameter1 + 1);
    (* FALTA IMPRIMIRLO*)
    done := true;
end;

procedure _DISPLAY;
begin
(* FALTA *)
done := true;(* FALTA COMPROBAR SI MARCA DONE *)
end;

procedure _CLS;
begin
 ClearCurrentWindow;
 done := true;
end;

procedure _DROPALL;
begin
(* FALTA *)
done := true;
end;

procedure _AUTOG;
begin
(* FALTA *)
end;

procedure _AUTOD;
begin
(* FALTA *)
end;

procedure _AUTOW;
begin
(* FALTA *)
end;

procedure _AUTOR;
begin
(* FALTA *)
end;

procedure _PAUSE;
begin
(* FALTA *)
done := true; 
end;

procedure _SYNONYM;
begin
 if (parameter1<>NO_WORD) then setFlag(FVERB, parameter1);
 if (parameter2<>NO_WORD) then setFlag(FNOUN, parameter1);
 done := true;
end;

procedure _GOTO;
begin
 setFlag(FPLAYER, Parameter1);
 done := true;
end;

procedure _MESSAGE;
begin
 _MES;
 _NEWLINE;
end;

procedure _REMOVE;
begin
(* FALTA *)
done := true;
end;

procedure _GET;
begin
(* FALTA *)
done := true;
end;

procedure _DROP;
begin
(* FALTA *)
done := true;
end;

procedure _WEAR;
begin
(* FALTA *)
done := true;
end;

procedure _DESTROY;
begin
  Parameter2 := LOC_NOT_CREATED;
 _PLACE;
end;

procedure _CREATE;
begin
 Parameter2 := getFlag(FPLAYER);
 _PLACE;
end;

procedure _SWAP;
var aux : TLocationType;
begin
 Aux := getObjectLocation(parameter1);
 setObjectLocation(parameter1, getObjectLocation(parameter2));
 setObjectLocation(parameter2, aux);
 SetReferencedObject(parameter2);
 done := true;
end;

procedure _PLACE;
begin
 if (getObjectLocation(parameter1) = LOC_CARRIED) then setFlag(FCARRIED, getFlag(FCARRIED) - 1);
 setObjectLocation(parameter1, parameter2);
 if (getObjectLocation(parameter1) = LOC_CARRIED) then setFlag(FCARRIED, getFlag(FCARRIED) +1);
 done := true;
end;

procedure _SET;
begin
 setFlag(Parameter1, MAX_FLAG_VALUE);
 done := true;
end;

procedure _CLEAR;
begin
 setFlag(Parameter1, 0);
 done := true;
end;

procedure _PLUS;
begin
 if getFlag(Parameter1) + Parameter2 > MAX_FLAG_VALUE then _SET
                                                      else setFlag(Parameter1, getFlag(Parameter1) + Parameter2);
 done := true;                                                      
end;

procedure _MINUS;
begin
 if getFlag(Parameter1) - Parameter2 <0  then _CLEAR
                                         else setFlag(parameter1, getFlag(Parameter1) - Parameter2);
 done := true;                                                        
end;

procedure _LET;
begin
 setFlag(Parameter1, parameter2);
 done := true;
end;

procedure _NEWLINE;
begin
 CarriageReturn;
 done := true;
end;

procedure _PRINT;
var value : TFlagtype;
begin
 value := getFlag(parameter1);
(* FALTA IMPRIMIR*)
 done := true;
end;

procedure _SYSMESS;
begin
 WriteText(getPcharMessage(DDBHeader.sysmessPos, parameter1));   
 done := true;
end;

procedure _ISAT;
begin
    condactResult := getObjectLocation(Parameter1) = parameter2;
end;

procedure _SETCO;
begin
  SetReferencedObject(parameter1);
  done := true;
end;

procedure _SPACE;
var Str: array[0..1] of char;
begin
    StrPCopy(Str, ' ');
    WriteText(@Str);
    done := true;
end;

procedure _HASAT;
var flag : TFlagType;
    bit : Word;
begin
    condactResult := getFlagBit(59-parameter1 div 8, parameter1 mod 8);
end;

procedure _HASNAT;
begin
    condactResult := not getFlagBit(59 - (parameter1 div 8), parameter1 mod 8);
end;

procedure _LISTOBJ;
begin
(* FALTA *)
done := true;
end;

procedure _EXTERN;
begin
(* FALTA *)
done := true;
end;

procedure _RAMSAVE;
begin
 RAMSaveFlags;
 RAMSaveObjects;
 done := true;
end;

procedure _RAMLOAD;
begin
 RAMLoadFlags(parameter1);
 RAMLoadObjects;
 done := true;
end;

procedure _BEEP;
begin
(* FALTA *)
done := true;
end;

procedure _PAPER;
begin
 PAPER := parameter1;
 done := true;
end;

procedure _INK;
begin
 INK := parameter1;
 done := true;
end;

procedure _BORDER;
begin
 BORDER := parameter1;
 done := true;
end;

procedure _PREP;
begin
 condactResult := getFlag(FPREP) = parameter1;
end;

procedure _NOUN2;
begin
 condactResult := getFlag(FNOUN2) = parameter1;
end;

procedure _ADJECT2;
begin
 condactResult := getFlag(FADJECT2) = parameter1;
end;

procedure _ADD;
begin
 if getFlag(Parameter1) +  getFlag(Parameter2) > MAX_FLAG_VALUE then setFlag(Parameter2, MAX_FLAG_VALUE)
                                                     else setFlag(Parameter2, getFlag(Parameter1) + getFlag(Parameter2));
done := true;
end;

procedure _SUB;
begin
 if getFlag(Parameter2) +  getFlag(Parameter1) <> 0 then setFlag(Parameter2, 0)
                                                    else setFlag(Parameter2, getFlag(Parameter2) + getFlag(Parameter1));
done := true;
end;

procedure _PARSE;
begin
 parse(parameter1);
 done := true; (* SALE CON DONE? mas bien al reves, no?*)
 {(* FALTA DAR SOPORTE A PARSE 1*)}
end;

procedure _LISTAT;
begin
(* FALTA *)
done := true;
end;

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
    {Done is not set, as it will basically depend on the PROCESS result}
end;

procedure _SAME;
begin
    condactResult := getFlag(Parameter1) = getFlag(parameter2);
end;

procedure _MES;
begin
  WriteText(getPcharMessage(DDBHeader.messagePos, parameter1));
  done := true;
end;

procedure _WINDOW;
begin
 if (parameter1<NUM_WINDOWS) then
 begin
    ActiveWindow := parameter1;
    SetFlag(FACTIVEWINDOW, parameter1);
 end;
 done := true;
end;

procedure _NOTEQ;
begin
    condactResult := getFlag(Parameter1) <> Parameter2;
end;

procedure _NOTSAME;
begin
    condactResult := getFlag(Parameter1) <> getFlag(parameter2);
end;

procedure _MODE;
begin
 Windows[ActiveWindow].OperationMode := parameter1;
 done := true;
end;

procedure _WINAT;
begin
 Windows[ActiveWindow].line := parameter1;
 Windows[ActiveWindow].col := parameter2;
 done := true;
end;

procedure _TIME;
begin
 SetFlag(FTIMEOUT, parameter1);
 SetFlag(FTIMEOUT_CONTROL, parameter2);
 done := true;
end;

procedure _PICTURE;
begin
(* FALTA *)
done := true;
end;

procedure _DOALL;
var objno: TFlagType;
begin
 DoallPTR := CondactPTR + 1; {Point to next Condact after DOALL}
 DoallEntryPTR := EntryPTR;
 objno := getNextObjectForDoall(-1, parameter1);
 SetFlag(FDOALL,objno);
 SetReferencedObject(objno);
 done := true; (* Falta ver si el DOALL en si hace done *)
end;

procedure _MOUSE;
begin
(* FALTA *)
done := true;
end;

procedure _GFX;
begin
(* FALTA *)
done := true;
end;

procedure _ISNOTAT;
begin
    condactResult := getObjectLocation(Parameter1) <> parameter2;
end;

procedure _WEIGH;
begin
 Setflag(parameter2, getObjectFullWeight(parameter1));
 done := true;
end;

procedure _PUTIN;
begin
(* FALTA *)
end;

procedure _TAKEOUT;
begin
(* FALTA *)
end;

procedure _NEWTEXT;
begin
    newtext;
    done := true;
end;

procedure _ABILITY;
begin
 setFlag(FOBJECTS_CONVEYABLE, Parameter1);
 setFlag(FPLAYER_STRENGTH, Parameter2);
 done := true;
end;

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

procedure _RANDOM;
begin
 SetFlag(parameter1, random(101));
 done := true;
end;

procedure _INPUT;
begin
(* FALTA *)
done := true;
end;

procedure _SAVEAT;
begin
  SaveAt;
  done := true;
end;

procedure _BACKAT;
begin
  BackAt;
  done := true;
end;

procedure _PRINTAT;
begin
  Printat(parameter1, parameter2);
  done := true;
end;

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
end; 


procedure _CALL;
begin
(* FALTA *)
done := true;
end;

procedure _PUTO;
begin
(* FALTA *)
done := true;
end;

procedure _NOTDONE;
begin
 done := false;
 ConsumeProcess; {Go to last entry}
 {force failure so we jump to next entry, which happens to be the mark of end of process}
 condactResult := false; 
end;

procedure _AUTOP;
begin
(* FALTA *)
end;

procedure _AUTOT;
begin
(* FALTA *)
end;

procedure _MOVE;
begin
(* FALTA *)
end;

procedure _WINSIZE;
begin
 Windows[ActiveWindow].height := parameter1;
 Windows[ActiveWindow].width := parameter2;
 done := true;
end;

procedure _REDO;
begin
  {Point two bytes below first entry because on return the engine will add 4}
  EntryPTR := getWord(ProcessPTR) - 4; 
  condactResult := false;  {force}
  (* falta poner el done = true ??*)
end;

procedure _CENTRE;
begin
(* FALTA *)
end;

procedure _EXIT;
begin
 if (parameter1 = 0) then halt(0);
 resetWindows;
 resetFlags;
 resetObjects;
 _RESTART;
end;

procedure _INKEY;
var inkey : word;
begin
  inkey := getKey;
  setflag(FKEY1, inkey and $FF);
  setflag(FKEY1, (inkey and $FF00) SHR 8);
  done := true;
end;

procedure _BIGGER;
begin
 condactResult := getFlag(Parameter1) > getFlag(Parameter2);
end;

procedure _SMALLER;
begin
 condactResult := getFlag(Parameter1) < getFlag(Parameter2);
end;

procedure _ISDONE;
begin
 condactResult := done;
end;

procedure _ISNDONE;
begin
 condactResult := not done;
end;

procedure _SKIP;
var OriginalSkip: integer;
begin
 OriginalSkip := parameter1 - 256; {Bring back the -128 to 127 value}
 EntryPTR := EntryPtr + 4 * OriginalSkip; 
 condactResult := false;
end;

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

procedure _TAB;
begin
 Tab(parameter1);
 done := true;
end;

procedure _COPYOF;
begin
 setFlag(parameter2, getObjectLocation(parameter1));
 done := true;
end;

procedure _COPYOO;
var aux: TFlagType;
begin
 {Its like placing objno2 at objno1 location}
 aux := parameter2;
 Parameter2 := getObjectLocation(parameter1);
 Parameter1 := aux;
 _PLACE;
end;

procedure _COPYFO;
var aux: TFlagType;
begin
 {Its like placing objno2 at flagno1}
 aux := parameter2;
 Parameter2 := getFlag(parameter1);
 Parameter1 := aux;
 _PLACE;
end;

procedure _dumb;
begin
end;

procedure _COPYFF;
begin
 SetFlag(Parameter2, getFlag(Parameter1));
 done := true;
end;

procedure _COPYBF;
begin
 SetFlag(Parameter1, getFlag(Parameter2));
 done := true;
end;

procedure _RESET;
begin
 resetObjects;
 resetFlags;
 done := true;
end;



end.
