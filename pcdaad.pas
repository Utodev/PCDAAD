{$I SETTINGS.INC}

(*
    This interpreter is (C) Uto (Carlos Sanchez) and is distributed under the MIT license.

    The code has been built with Borland Pascal 7.0, although it's likely to work fine 
    with Turbo Pascal 7.0 and Turbo pascal 6.0

*)


program PCDAAD;

uses strings, global, ddb, errors, stack, condacts, flags, objects, graph, utils, parser;

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
 
 Debug('[RunEntry]  ProcessPtr: ' + intToHex(ProcessPTR) + ' | EntryPtr  : ' + intToHex(EntryPTR));
 
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
      Debug('Doall loop, jumping back with object '+ inttostr(nextDoallObjno));
      SetReferencedObject(nextDoallObjno);
      goto RunCondact;
    end
    else  
    begin
      {If in DOALL but no more objects mark doall inactive and just let }
      {the process continue and finish normally}
      Debug('Doall loop but no more objects at location ' + inttostr(DoallLocation));
      DoallPTR := 0; 
    end;
  end;

  {process finishes normally}
  Debug('End of Proces found - no more entries');
  StackPop;
  Debug('Pp ProPtr:' + inttostr(ProcessPtr) + ' EntryPtr:' + inttostr(EntryPtr)+ ' CondactPtr: '+ inttostr(condactPTR));
  condactPTR := condactPTR + 1;
  Goto RunCondact;
 end;

 Debug('Validating entry ' + inttostr(getByte(EntryPTR)) + ' ' + inttostr(getByte(EntryPTR+1)));
 
 ValidEntry := ((getByte(EntryPTR) = getFlag(FVERB)) OR (getByte(EntryPTR) = NO_WORD))
                 and ((getByte(EntryPTR+1) = getFlag(FNOUN)) OR (getByte(EntryPTR+1) = NO_WORD));
 CondactPTR := getWord(EntryPTR + 2);

 if not ValidEntry then
 begin
  Debug('Entry not valid');
  EntryPTR := EntryPTR + 4;
  goto RunEntry;
 end; 

 RunCondact:
 {First check if no more condacts in the entry, if so, move to next entry}
 Debug('Getting next condact');
 condactResult := true;
 opcode := getByte(CondactPTR);
 if opcode = END_OF_CONDACTS_MARK then
 begin
  Debug('End of condacts mark found. No more condacts in this entry');
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
 if (Indirection) then DebugStr := DebugStr + '@';
 
 {get parameters}
 if (condactTable[opcode].numParams>0) then
 begin
  CondactPTR := CondactPTR + 1;
  Parameter1 := getByte(CondactPTR);
  DebugStr := DebugStr + inttostr(Parameter1) + ' ';
  if Indirection then parameter1 := getFlag(Parameter1);
  if (condactTable[opcode].numParams>1) then
  begin
   CondactPTR := CondactPTR + 1;
   Parameter2 := getByte(CondactPTR);
   DebugStr := DebugStr + inttostr(Parameter2);
  end;
 end;
 Debug('>> ' + DebugStr);

 {run condact}
 {$ifdef DEBUG}
 Delay(1);
 {$endif}
 condactResult := true;
 condactTable[opcode].condactRoutine; {Execute the condact}
 {If condact execution failed, go to next entry}
 if (condactResult = false) then
 begin
  Debug('Condition failed, jumping to next entry');
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
