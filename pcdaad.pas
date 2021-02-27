{$I SETTINGS.INC}

(*
    This interpreter is (C) 2021 Uto (Carlos Sanchez) and is distributed under the
    MIT license.

    This code is to be built with Borland Pascal 7.0, although it's likely to work
    fine with Turbo Pascal 7.0 and maybe with Turbo pascal 6.0
*)

program PCDAAD;

uses strings, global, ddb, errors, stack, condacts, flags, objects, graph, utils, parser, ibmpc;

var ddbFilename : String;

var  Indirection, ValidEntry :  boolean;
     Opcode : TOpcodeType;
     i, j : integer;
     DebugStr :String;

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

  {If DOALL loop in execution}
  if DoallPTR <> 0 then 
  begin
    {Try to get next object at the doall location}
    nextDoallObjno := getNextObjectAt(getFlag(FDOALL), DoallLocation);
    {If a valid object found jump back to DOALL entry/condact}
    if nextDoallObjno <> MAX_OBJECT then
    begin
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
    end;
  end;

  {process finishes normally}
  StackPop;
  condactPTR := condactPTR + 1;
  Goto RunCondact;
 end;

(*
 Debug('Entry:' + inttostr(getByte(EntryPTR)) + ' ' + inttostr(getByte(EntryPTR+1)));
 Debug('LS   :' + inttostr(getFlag(FVERB)) + ' ' + inttostr(getFlag(FNOUN)));
 *)
 
 ValidEntry := ((getByte(EntryPTR) = getFlag(FVERB)) OR (getByte(EntryPTR) = NO_WORD))
                 and ((getByte(EntryPTR+1) = getFlag(FNOUN)) OR (getByte(EntryPTR+1) = NO_WORD));
 CondactPTR := getWord(EntryPTR + 2);

 if not ValidEntry then
 begin
  EntryPTR := EntryPTR + 4;
  goto RunEntry;
 end; 

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
 {$ifdef DEBUG}
 DebugStr := condactTable[opcode].condactName + ' ';
 if (Indirection) then DebugStr := DebugStr + '@';
 {$endif}
 
 {get parameters}
 if (condactTable[opcode].numParams>0) then
 begin
  CondactPTR := CondactPTR + 1;
  Parameter1 := getByte(CondactPTR);
  DebugStr := DebugStr + inttostr(Parameter1) + ' ';
  if Indirection then parameter1 := getFlag(Parameter1);
  if Indirection then DebugStr := DebugStr + '('+inttostr(parameter1)+') ';
  if (condactTable[opcode].numParams>1) then
  begin
   CondactPTR := CondactPTR + 1;
   Parameter2 := getByte(CondactPTR);
   DebugStr := DebugStr + inttostr(Parameter2);
  end;
 end;
 
 {run condact}
 Debug('>> ' + DebugStr);
 {$ifdef DEBUG}
 {Delay(0.001);}
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

(************************************************************************************************)
(**************************************** MAIN **************************************************)
(************************************************************************************************)
begin
    Writeln('PC DAAD Interpreter ',version,' (C) Uto 2021');
    Debug('DEBUG MODE ON');
    if (ParamCount>0) then ddbFilename := ParamStr(1) else ddbFilename := 'DAAD.DDB';
    if (not loadDDB(ddbFilename)) then Error(1, 'DDB file not found or invalid.');
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
