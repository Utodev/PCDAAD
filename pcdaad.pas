{$I SETTINGS.INC}

(*
    This interpreter is (C) 2021 Uto (Carlos Sanchez) and is distributed under the
    MIT license.

    This code is to be built with Borland Pascal 7.0, although it's likely to work
    fine with Turbo Pascal 7.0 and maybe with Turbo pascal 6.0

    Greetings: 
    + to Natalia Pujol for her help with BEEP condact
    + to Rogerio Biondi and Daniel Carbonell, the very first alpha testers of this interpreter
*)


program PCDAAD;

uses strings, global, ddb, errors, stack, condacts, flags, objects, graph, utils, parser, ibmpc, charset, log, pcx, maluva;

var ddbFilename : String;

var  Indirection, ValidEntry :  boolean;
     Opcode : TOpcodeType;
     i, j : integer;
     DebugStr : String;

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
    TranscriptPas('{Last doall object:'+ inttostr(getFlag(FDOALL))+'}'+#13);
    nextDoallObjno := getNextObjectAt(getFlag(FDOALL), DoallLocation);
    TranscriptPas('{Next doall object:'+ inttostr(nextDoallObjno)+'}'+#13);
    {If a valid object found jump back to DOALL entry/condact}
    if nextDoallObjno <> MAX_OBJECT then
    begin
      TranscriptPas('{Doall loops}'+#13);
      EntryPTR := DoallEntryPTR;
      CondactPTR :=  DoallPTR;
      SetReferencedObject(nextDoallObjno);
      SetFlag(FDOALL, nextDoallObjno);
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

 {These flags should have specific values that code can use to determine the machine running the DDB
  so they are being set after every condact to make sure even when modified, their value is restored} 
 SetFlag(FSCREENMODE, 13 + 128); {Makes sure flag 62 has proper value: mode 13 (VGA or EGA) and bit 7 set}
 SetFlag(FMOUSE, 128); {Makes sure flag 29 has "graphics" available set, and the rest is empty}

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
  WriteLn('Usage: ' + ParamStr(0) + ' [DDB file] [-nolog] [-nomaluva] [-i<orders file>] [-d] [-h]');
  WriteLn;
  WriteLn('DDB File : a valid DAAD DDB file made for PC/DOS. Defaults to DAAD.DDB');
  WriteLn('-nolog : don''t dump transcript on PCDAAD.LOG');
  WriteLn('-nomaluva : turns off Maluva extension emulation');
  WriteLn('-i<orders file> : take player orders from text file until exhausted');
  WriteLn('-d : enable diagnostics');
  WriteLn('-h : shows this help');
  Halt(0);
end;

procedure ParseParameters;
var i : integer;
begin
 for i:=1 to ParamCount do
 begin
  if StrToUpper(ParamStr(i)) = '-H' then Help
  else if StrToUpper(ParamStr(i)) = '-NOLOG' then TranscriptDisabled := true
  else if StrToUpper(ParamStr(i)) = '-D' then DiagnosticsEnabled := true
  else if StrToUpper(ParamStr(i)) = '-NOMALUVA' then MaluvaDisabled := true
  else if Copy(StrToUpper(ParamStr(i)),1,2) = '-I' then 
  begin
   useOrderInputFile := true;
   orderInputFileName := Copy(ParamStr(i),3,255);
  end 
  else if Copy(StrToUpper(ParamStr(i)),1,1) <> '-' then {If no hyphen, then it's DDB name}
  begin
   ddbFilename := ParamStr(i);
  end
  else Error(10,'Invalid or unknown parameter: ' + ParamStr(i));
 end;
end; 

(************************************************************************************************)
(**************************************** MAIN **************************************************)
(************************************************************************************************)
begin
    CopyRight;
    ddbFilename := 'DAAD.DDB';
    ParseParameters;
    if (not loadDDB(ddbFilename)) then Error(1, 'DDB file not found or invalid.');
    {$ifdef VGA}
    if (not loadCharset('DAAD.FNT')) then Error(6, 'PCDAAD.FNT file not found or invalid.');
    {$endif}

    InitTranscript('pcdaad.log');
    TranscriptPas('PCDAAD Log ' + VERSION + #13);
    
    InitOrderFile;
    
    Randomize;        {Initialize the random generator}
    startVideoMode;   {Set the proper video mode}
    InitializeParser; {Initializes the parser}
    resetFlags;       {Restores flags initial value}
    resetObjects;     {Restore objects to "initially at" locations}
    resetWindows;     {clears all windows setup}
    resetStack;
    resetProcesses;
    if loadPCX(0,0,LINE_WIDTH,200, 65535) then  {Load intro screen if present}
    begin
      DisplayPCX(0); {Paint the picture}
      while not Keypressed do;
      ReadKey;
      DisplayPCX(1); {Clear the PCX Window}
    end; 
    run; {there is no way back from this procedure, so cleaning isn't here}
end.
