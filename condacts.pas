(* All the condacts stuff, including implementation of condacts *)

{$I SETTINGS.INC}

unit condacts;

interface

uses global;

const MAX_CONDACTS = 128;

type TCondactType = record
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
(condactRoutine: _AT     ; numParams: 1), {   0 $00}
(condactRoutine: _NOTAT  ; numParams: 1), {   1 $01}
(condactRoutine: _ATGT   ; numParams: 1), {   2 $$02}
(condactRoutine: _ATLT   ; numParams: 1), {   3 $03}
(condactRoutine: _PRESENT; numParams: 1), {   4 $04}
(condactRoutine: _ABSENT ; numParams: 1), {   5 $05}
(condactRoutine: _WORN   ; numParams: 1), {   6 $06}
(condactRoutine: _NOTWORN; numParams: 1), {   7 $07}
(condactRoutine: _CARRIED; numParams: 1), {   8 $08}
(condactRoutine: _NOTCARR; numParams: 1), {   9 $09}
(condactRoutine: _CHANCE ; numParams: 1), {  10 $0A}
(condactRoutine: _ZERO   ; numParams: 1), {  11 $0B}
(condactRoutine: _NOTZERO; numParams: 1), {  12 $0C}
(condactRoutine: _EQ     ; numParams: 1), {  13 $0D}
(condactRoutine: _GT     ; numParams: 1), {  14 $0E}
(condactRoutine: _LT     ; numParams: 1), {  15 $0F}
(condactRoutine: _ADJECT1; numParams: 1), {  16 $10}
(condactRoutine: _ADVERB ; numParams: 1), {  17 $11}
(condactRoutine: _SFX    ; numParams: 1), {  18 $12}
(condactRoutine: _DESC   ; numParams: 1), {  19 $13}
(condactRoutine: _QUIT   ; numParams: 1), {  20 $14}
(condactRoutine: _END    ; numParams: 1), {  21 $15}
(condactRoutine: _DONE   ; numParams: 1), {  22 $16}
(condactRoutine: _OK     ; numParams: 1), {  23 $17}
(condactRoutine: _ANYKEY ; numParams: 1), {  24 $18}
(condactRoutine: _SAVE   ; numParams: 1), {  25 $19}
(condactRoutine: _LOAD   ; numParams: 1), {  26 $1A}
(condactRoutine: _DPRINT ; numParams: 1), {  27 $1B}
(condactRoutine: _DISPLAY; numParams: 1), {  28 $1C}
(condactRoutine: _CLS    ; numParams: 1), {  29 $1D}
(condactRoutine: _DROPALL; numParams: 1), {  30 $1E}
(condactRoutine: _AUTOG  ; numParams: 1), {  31 $1F}
(condactRoutine: _AUTOD  ; numParams: 1), {  32 $20}
(condactRoutine: _AUTOW  ; numParams: 1), {  33 $21}
(condactRoutine: _AUTOR  ; numParams: 1), {  34 $22}
(condactRoutine: _PAUSE  ; numParams: 1), {  35 $23}
(condactRoutine: _SYNONYM; numParams: 1), {  36 $24}
(condactRoutine: _GOTO   ; numParams: 1), {  37 $25}
(condactRoutine: _MESSAGE; numParams: 1), {  38 $26}
(condactRoutine: _REMOVE ; numParams: 1), {  39 $27}
(condactRoutine: _GET    ; numParams: 1), {  40 $28}
(condactRoutine: _DROP   ; numParams: 1), {  41 $29}
(condactRoutine: _WEAR   ; numParams: 1), {  42 $2A}
(condactRoutine: _DESTROY; numParams: 1), {  43 $2B}
(condactRoutine: _CREATE ; numParams: 1), {  44 $2C}
(condactRoutine: _SWAP   ; numParams: 1), {  45 $2D}
(condactRoutine: _PLACE  ; numParams: 1), {  46 $2E}
(condactRoutine: _SET    ; numParams: 1), {  47 $2F}
(condactRoutine: _CLEAR  ; numParams: 1), {  48 $30}
(condactRoutine: _PLUS   ; numParams: 1), {  49 $31}
(condactRoutine: _MINUS  ; numParams: 1), {  50 $32}
(condactRoutine: _LET    ; numParams: 1), {  51 $33}
(condactRoutine: _NEWLINE; numParams: 1), {  52 $34}
(condactRoutine: _PRINT  ; numParams: 1), {  53 $35}
(condactRoutine: _SYSMESS; numParams: 1), {  54 $36}
(condactRoutine: _ISAT   ; numParams: 1), {  55 $37}
(condactRoutine: _SETCO  ; numParams: 1), {  56 $38}
(condactRoutine: _SPACE  ; numParams: 1), {  57 $39}
(condactRoutine: _HASAT  ; numParams: 1), {  58 $3A}
(condactRoutine: _HASNAT ; numParams: 1), {  59 $3B}
(condactRoutine: _LISTOBJ; numParams: 1), {  60 $3C}
(condactRoutine: _EXTERN ; numParams: 1), {  61 $3D}
(condactRoutine: _RAMSAVE; numParams: 1), {  62 $3E}
(condactRoutine: _RAMLOAD; numParams: 1), {  63 $3F}
(condactRoutine: _BEEP   ; numParams: 1), {  64 $40}
(condactRoutine: _PAPER  ; numParams: 1), {  65 $41}
(condactRoutine: _INK    ; numParams: 1), {  66 $42}
(condactRoutine: _BORDER ; numParams: 1), {  67 $43}
(condactRoutine: _PREP   ; numParams: 1), {  68 $44}
(condactRoutine: _NOUN2  ; numParams: 1), {  69 $45}
(condactRoutine: _ADJECT2; numParams: 1), {  70 $46}
(condactRoutine: _ADD    ; numParams: 1), {  71 $47}
(condactRoutine: _SUB    ; numParams: 1), {  72 $48}
(condactRoutine: _PARSE  ; numParams: 1), {  73 $49}
(condactRoutine: _LISTAT ; numParams: 1), {  74 $4A}
(condactRoutine: _PROCESS; numParams: 1), {  75 $4B}
(condactRoutine: _SAME   ; numParams: 1), {  76 $4C}
(condactRoutine: _MES    ; numParams: 1), {  77 $4D}
(condactRoutine: _WINDOW ; numParams: 1), {  78 $4E}
(condactRoutine: _NOTEQ  ; numParams: 1), {  79 $4F}
(condactRoutine: _NOTSAME; numParams: 1), {  80 $50}
(condactRoutine: _MODE   ; numParams: 1), {  81 $51}
(condactRoutine: _WINAT  ; numParams: 1), {  82 $52}
(condactRoutine: _TIME   ; numParams: 1), {  83 $53}
(condactRoutine: _PICTURE; numParams: 1), {  84 $54}
(condactRoutine: _DOALL  ; numParams: 1), {  85 $55}
(condactRoutine: _MOUSE  ; numParams: 1), {  86 $56}
(condactRoutine: _GFX    ; numParams: 1), {  87 $57}
(condactRoutine: _ISNOTAT; numParams: 1), {  88 $58}
(condactRoutine: _WEIGH  ; numParams: 1), {  89 $59}
(condactRoutine: _PUTIN  ; numParams: 1), {  90 $5A}
(condactRoutine: _TAKEOUT; numParams: 1), {  91 $5B}
(condactRoutine: _NEWTEXT; numParams: 1), {  92 $5C}
(condactRoutine: _ABILITY; numParams: 1), {  93 $5D}
(condactRoutine: _WEIGHT ; numParams: 1), {  94 $5E}
(condactRoutine: _RANDOM ; numParams: 1), {  95 $5F}
(condactRoutine: _INPUT  ; numParams: 1), {  96 $60}
(condactRoutine: _SAVEAT ; numParams: 1), {  97 $61}
(condactRoutine: _BACKAT ; numParams: 1), {  98 $62}
(condactRoutine: _PRINTAT; numParams: 1), {  99 $63}
(condactRoutine: _WHATO  ; numParams: 1), { 100 $64}
(condactRoutine: _CALL   ; numParams: 1), { 101 $65}
(condactRoutine: _PUTO   ; numParams: 1), { 102 $66}
(condactRoutine: _NOTDONE; numParams: 1), { 103 $67}
(condactRoutine: _AUTOP  ; numParams: 1), { 104 $68}
(condactRoutine: _AUTOT  ; numParams: 1), { 105 $69}
(condactRoutine: _MOVE   ; numParams: 1), { 106 $6A}
(condactRoutine: _WINSIZE; numParams: 1), { 107 $6B}
(condactRoutine: _REDO   ; numParams: 1), { 108 $6C}
(condactRoutine: _CENTRE ; numParams: 1), { 109 $6D}
(condactRoutine: _EXIT   ; numParams: 1), { 110 $6E}
(condactRoutine: _INKEY  ; numParams: 1), { 111 $6F}
(condactRoutine: _BIGGER ; numParams: 1), { 112 $70}
(condactRoutine: _SMALLER; numParams: 1), { 113 $71}
(condactRoutine: _ISDONE ; numParams: 1), { 114 $72}
(condactRoutine: _ISNDONE; numParams: 1), { 115 $73}
(condactRoutine: _SKIP   ; numParams: 1), { 116 $74}
(condactRoutine: _RESTART; numParams: 1), { 117 $75}
(condactRoutine: _TAB    ; numParams: 1), { 118 $76}
(condactRoutine: _COPYOF ; numParams: 1), { 119 $77}
(condactRoutine: _dumb   ; numParams: 1), { 120 $78}
(condactRoutine: _COPYOO ; numParams: 1), { 121 $79}
(condactRoutine: _dumb   ; numParams: 1), { 122 $7A}
(condactRoutine: _COPYFO ; numParams: 1), { 123 $7B}
(condactRoutine: _dumb   ; numParams: 1), { 124 $7C}
(condactRoutine: _COPYFF ; numParams: 1), { 125 $7D}
(condactRoutine: _COPYBF ; numParams: 1), { 126 $7E}
(condactRoutine: _RESET  ; numParams: 1)  { 127 $7F}
);

implementation



uses flags, ddb, objects, pc, graph;


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
(* FALTA *)
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
 (* FALTA HACER QUE SALTE AL FINAL DE TABLA *)
 done := true;
end;

procedure _OK;
begin
 Parameter1 := 15; {"OK"}
 _SYSMESS;
 _DONE;
end;

procedure _ANYKEY;
begin
 while getKey = 0 do;
 done := true; (* FALTA COMPROBAR SI ANYKEY MARCA DONE *)
end;

procedure _SAVE;
begin
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
(* FALTA *)
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
done := true; (* FALTA COMPROBAR SI MARCA DONE*)
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
(* FALTA *)
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
 (* FALTA *)
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
begin
(* FALTA *)
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
(* FALTA *)
done := true;
end;

procedure _LISTAT;
begin
(* FALTA *)
done := true;
end;

procedure _PROCESS;
begin
(* FALTA *)
done := true; (*FALTA ¿Seguro?*)
end;

procedure _SAME;
begin
    condactResult := getFlag(Parameter1) = getFlag(parameter2);
end;

procedure _MES;
begin
(* FALTA *)
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
begin
 DoallPTR := CondactPTR;
 SetFlag(FDOALL,0);
 SetReferencedObject(0);
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
    (* FALTA *)
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
begin
(* FALTA *)
done := true;
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
(* FALTA  LO DE HACER QUE SALTE AL FINAL DE PROCESO*)
  done := false;
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
(* FALTA *)
end;

procedure _CENTRE;
begin
(* FALTA *)
end;

procedure _EXIT;
begin
(* FALTA *)
end;

procedure _INKEY;
begin
(* FALTA *)
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
begin
(*FALTA*)
 done := true;
end;

procedure _RESTART;
begin
(*FALTA*)
 done := true;
end;

procedure _TAB;
begin
(*FALTA*)
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
(* falta *)
 done := true;
end;



end.