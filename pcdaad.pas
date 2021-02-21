{$I SETTINGS.INC}

(*
    This interpreter is (C) Uto (Carlos Sanchez) and is distributed under the MIT license.

    The code has been built with Borland Pascal 7.0, although it's likely to work fine 
    with Turbo Pascal 7.0 and Turbo pascal 6.0

*)


program PCDAAD;

uses strings, global, ddb, errors, stack, condacts, flags, objects, graph, utils;

var ddbFilename : String;

var  Indirection, ValidEntry :  boolean;
     Opcode : TOpcodeType;
     i, j : integer;


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
 
 Debug('>-------------------');
 Debug('ProcessPtr: ' + intToHex(ProcessPTR));
 Debug('EntryPtr  : ' + intToHex(EntryPTR));
 
 {Check if current process has finished}
 if getByte(EntryPTR) = END_OF_PROCESS_MARK then 
 begin 

  {If DOALL loop in execution}
  if DoallPTR <> 0 then 
  begin
    {Try to get next object at the doall location}
    nextDoallObjno := getNextObjectForDoall(getFlag(FDOALL), DoallLocation);
    {If a valid object found jump back to DOALL entry/condact}
    if nextDoallObjno <> MAX_OBJECT then
    begin
      EntryPTR := DoallEntryPTR;
      CondactPTR :=  DoallPTR;
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
  Goto RunEntry;
 end;

 Debug('Entry evaluation: ' +   inttostr(getByte(EntryPTR)) + ' '    + inttostr(getByte(EntryPTR+1)));
 
 ValidEntry := ((getByte(EntryPTR) = getFlag(FVERB)) OR (getByte(EntryPTR) = NO_WORD))
                 and ((getByte(EntryPTR+1) = getFlag(FNOUN)) OR (getByte(EntryPTR+1) = NO_WORD));
 CondactPTR := getWord(EntryPTR + 2);

 if not ValidEntry then
 begin
  Debug('Not valid entry');
  EntryPTR := EntryPTR + 2;
  goto RunEntry;
 end; 

 RunCondact:
 {First check if no more condacts in the entry, if so, move to next entry}
 condactResult := true;
 opcode := getByte(CondactPTR);
 if opcode = END_OF_CONDACTS_MARK then
 begin
  Debug('End of entry');
  EntryPTR := EntryPTR + 2;
  goto RunEntry;
 end; 

 {Let's run the condact}
 if (opcode AND $80 <> 0) then
 begin
  Indirection := true;
  opcode := opcode AND $7F;
 end
 else Indirection := false;
 Debug('Opcode      : ' + condactTable[opcode].condactName);
 Debug('Indirection : ' + inttostr(byte(Indirection)));

 {get parameters}
 if (condactTable[opcode].numParams>0) then
 begin
  CondactPTR := CondactPTR + 1;
  Parameter1 := getByte(CondactPTR);
  Debug('P1: ' + inttostr(Parameter1));
  if Indirection then parameter1 := getFlag(Parameter1);
  if (condactTable[opcode].numParams>1) then
  begin
   CondactPTR := CondactPTR + 1;
   Parameter2 := getByte(CondactPTR);
   Debug('P1: ' + inttostr(Parameter2));
  end;
 end;

 {run}
 condactResult := true;
 condactTable[opcode].condactRoutine; {Execute the condact}
 {If condact execution failed, go to next entry}
 Debug('CondactResult: ' + inttostr(byte(condactResult)));
 if (condactResult = false) then
 begin
  EntryPTR := EntryPTR + 2;
  goto RunEntry;
 end;
 {otherwise go to next condact}
 condactPTR := CondactPTR + 1;
 goto RunCondact;


end;

begin
    Writeln('PC DAAD Interpreter ',version,' (C) Uto 2021');
    Debug('DEBUG MODE ON');
    if (ParamCount>0) then ddbFilename := ParamStr(1) else ddbFilename := 'DAAD.DDB';
    if (not loadDDB(ddbFilename)) then Error(1, 'DDB file not found or invalid.');
    Randomize;      {Initialize the random generator}
    startVideoMode;
    resetFlags;     {Restore flags initial value}
    resetObjects;   {Restore objects to "initially at" locations}
    resetWindows;   {redefine all windows}
    resetStack;
    resetProcesses;
    run;
end.
