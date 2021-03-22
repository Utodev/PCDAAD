{$I SETTINGS.INC}

(*
    This interpreter is (C) 2021 Uto (Carlos Sanchez) and is distributed under the
    MIT license.

    This code is to be built with Borland Pascal 7.0, although it's likely to work
    fine with Turbo Pascal 7.0 and maybe with Turbo pascal 6.0

    Greetings: to Natalia Pujol for her help with BEEP condact
*)

program PCDAAD;

uses strings, global, ddb, errors, stack, condacts, flags, objects, graph, utils, parser, ibmpc, charset, log;

var ddbFilename : String;

var  Indirection, ValidEntry :  boolean;
     Opcode : TOpcodeType;
     i, j : integer;
     DebugStr : String;
     TranscriptUnit : String;

{ OK, this code runs the processes in a very assembly style, that's why the labels  }
{ and GOTO are used. It would have been possible to make a structured code with     }
{ several while loops and conditions, but code would have been a much less readable }
procedure run;
label RunEntry, RunCondact;
var nextDoallObjno: TFlagType;
begin
 done := false;

 {Where a new entry is considered and evaluated}
 RunEntry:

 {Check if current process has finished}
 if getByte(EntryPTR) = END_OF_PROCESS_MARK then
 begin
  TranscriptPas('{End Of Process found}'+#13);
  {If DOALL loop in execution}
  if DoallPTR <> 0 then 
  begin
    TranscriptPas('{In Doall}'+#13)  ;
    {Try to get next object at the doall location}
    nextDoallObjno := getNextObjectAt(getFlag(FDOALL), DoallLocation);
    TranscriptPas('{Next object:'+ inttostr(nextDoallObjno)+'}'+#13);
    {If a valid object found jump back to DOALL entry/condact}
    if nextDoallObjno <> MAX_OBJECT then
    begin
      TranscriptPas('{Doall loops}'+#13);
      EntryPTR := DoallEntryPTR;
      CondactPTR :=  DoallPTR;
      SetReferencedObject(nextDoallObjno);
      goto RunCondact;
    end
    else  
    begin
      {If in DOALL but no more objects mark doall inactive and just let }
      {the process continue and finish normally}
      DoallPTR := 0; 
      TranscriptPas('{Doall finished}'+#13);
    end;
  end;

  {process finishes normally}
  StackPop;
  condactPTR := condactPTR + 1;
  Goto RunCondact;
 end;

 ValidEntry := ((getByte(EntryPTR) = getFlag(FVERB)) OR (getByte(EntryPTR) = NO_WORD))
                 and ((getByte(EntryPTR+1) = getFlag(FNOUN)) OR (getByte(EntryPTR+1) = NO_WORD));
 CondactPTR := getWord(EntryPTR + 2);

 if not ValidEntry then
 begin
  EntryPTR := EntryPTR + 4;
  goto RunEntry;
 end; 

 TranscriptPas('{> ' + getVocabulary(VOC_VERB, getByte(EntryPTR)) +' ' + getVocabulary(VOC_NOUN,getByte(EntryPTR+1))); 
 TranscriptPas(' matches ' + getVocabulary(VOC_VERB, getFlag(FVERB)) 
              + ' ' + getVocabulary(VOC_NOUN, getFlag(FNOUN)) +' }'#13);

 RunCondact:
 {First check if no more condacts in the entry, if so, move to next entry}
 condactResult := true;
 opcode := getByte(CondactPTR);
 if opcode = END_OF_CONDACTS_MARK then
 begin
  EntryPTR := EntryPTR + 4;
  goto RunEntry;
 end; 
 
 {Let's run the condact}
 if (opcode AND $80 <> 0) then
 begin
  Indirection := true;
  opcode := opcode AND $7F;
 end
 else Indirection := false;
 DebugStr := condactTable[opcode].condactName + ' ';
 if Indirection then DebugStr := DebugStr + '@';
 
 {get parameters}
 if (condactTable[opcode].numParams>0) then
 begin
  CondactPTR := CondactPTR + 1;
  Parameter1 := getByte(CondactPTR);
  DebugStr := DebugStr + IntToStr(Parameter1) + ' ';
  if Indirection then 
  begin
   parameter1 := getFlag(Parameter1);
   DebugStr := DebugStr + '(' + IntToStr(parameter1) +') ';
  end; 
  if (condactTable[opcode].numParams>1) then
  begin
   CondactPTR := CondactPTR + 1;
   Parameter2 := getByte(CondactPTR);
   DebugStr := DebugStr + IntToStr(parameter2);
  end;
 end;
 
 {run condact}
 TranscriptPas('{'+DebugStr+'}'+#13);
 {$ifdef DEBUG}
 (*WriteTextPas('{'+DebugStr+'}'+#13, true);}*)
 {$endif}
 condactResult := true;
 condactTable[opcode].condactRoutine; {Execute the condact}
 {If condact execution failed, go to next entry}
 if (condactResult = false) then
 begin
  EntryPTR := EntryPTR + 4;
  goto RunEntry;
 end;
 {otherwise go to next condact}
 condactPTR := CondactPTR + 1;
 goto RunCondact;
end;

procedure help;
begin
  WriteLn;
  WriteLn('Usage: ' + ParamStr(0) + ' [DDB file] [Transcript file]');
  WriteLn;
  WriteLn('DDB File: a valid DAAD DDB file made for PC/DOS. Defaults to DAAD.DDB');
  WriteLn('Trascript file: Defaults to PCDAAD.LOG');
  Halt(0);
end;

(************************************************************************************************)
(**************************************** MAIN **************************************************)
(************************************************************************************************)
begin
    Writeln('PC DAAD Interpreter ',version,' (C) Uto 2021');
    if (ParamCount>0) and ((ParamStr(1)='?') or (ParamStr(1)='/?') or (ParamStr(1)='/h')) then help;
    Debug('DEBUG MODE ON');
    if (ParamCount>0) then ddbFilename := ParamStr(1) else ddbFilename := 'DAAD.DDB';
    if (not loadDDB(ddbFilename)) then Error(1, 'DDB file not found or invalid.');
    {$ifdef VGA}
    if (not loadCharset('DAAD.FNT')) then Error(6, 'PCDAAD.FNT file not found or invalid.');
    {$endif}
    if (ParamCount>1) then 
    begin
      InitTranscript(ParamStr(2));
      if ParamStr(2)='NOLOG' then TranscriptDisabled := true;
    end else InitTranscript('pcdaad.log');
    
    TranscriptUnit := ParamStr(0);
    TranscriptUnit :=  Upcase(TranscriptUnit[1]);
    if (TranscriptUnit='A') or (TranscriptUnit='B') then TranscriptDisabled := true;
    
    Randomize;        {Initialize the random generator}
    startVideoMode;   {Set the proper video mode}
    InitializeParser; {Initializes the parser}
    resetFlags;       {Restores flags initial value}
    resetObjects;     {Restore objects to "initially at" locations}
    resetWindows;     {clears all windows setup}
    resetStack;
    resetProcesses;
    run;
end.
