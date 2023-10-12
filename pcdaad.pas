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

(* Pending: no funciona concatenar ordenes *)
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
  if Verbose then TranscriptPas('{End Of Process found}'+#13);
  {If DOALL loop in execution}
  if DoallPTR <> 0 then 
  begin
    if Verbose then TranscriptPas('{In Doall}'+#13)  ;
    {Try to get next object at the doall location}
    if Verbose then TranscriptPas('{Last doall object:'+ inttostr(getFlag(FDOALL))+'}'+#13);
    repeat
      nextDoallObjno := getNextObjectAt(getFlag(FDOALL), DoallLocation);
      if Verbose then TranscriptPas('{Next doall object:'+ inttostr(nextDoallObjno)+'}'+#13);
      {If a valid object found jump back to DOALL entry/condact}
      if nextDoallObjno <> MAX_OBJECT then
      begin
        if Verbose then TranscriptPas('{Doall loops}'+#13);
        SetReferencedObject(nextDoallObjno);
        SetFlag(FDOALL, nextDoallObjno);
       
        {Checking if OBJ2 is the same as OBJ1, to support EXCEPT and also to avoid what Issue#4 in Github details}
        if (getFlag(FNOUN) = getFlag(FNOUN2)) and  
        ( (getFlag(FADJECT) = getFlag(FADJECT2))
          or (getFlag(FADJECT) = NO_WORD)
          or (getFlag(FADJECT2) = NO_WORD) ) then
          begin
            if Verbose then TranscriptPas('{"Except" applied to Doall, skipping object}'+#13);
            continue;
          end;
      
        EntryPTR := DoallEntryPTR;
          CondactPTR :=  DoallPTR;
        goto RunCondact;
      end
      else  
      begin
        {If in DOALL but no more objects mark doall inactive and just let }
        {the process continue and finish normally}
        DoallPTR := 0; 
        if Verbose then TranscriptPas('{Doall finished}'+#13);
        break;
      end;
    until false;


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

 if Verbose then TranscriptPas('{> ' + getVocabulary(VOC_VERB, getByte(EntryPTR)) 
              + ' ' + getVocabulary(VOC_NOUN,getByte(EntryPTR+1))); 
 if Verbose then TranscriptPas(' matches ' + getVocabulary(VOC_VERB, getFlag(FVERB)) 
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
 if Verbose then TranscriptPas('{'+DebugStr+'}'+#13);
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
  WriteLn('Usage: ' + ParamStr(0) + ' [DDB file] [-s] [-log] [-vlog] [-nomaluva] [-exec] [-i<orders file>] [-d] [-h]');
  WriteLn;
  WriteLn('DDB File : a valid DAAD DDB file made for PC/DOS. Defaults to DAAD.DDB');
  WriteLn('-s : SVGA mode');
  WriteLn('-log : Transcript game to PCDAAD.LOG');
  WriteLn('-vlog : Transcript game, condacts and useful information to PCDAAD.LOG (verbose log)');
  WriteLn('-nomaluva : turns off Maluva extension emulation');
  WriteLn('-exec : use executables as EXTERN code');
  WriteLn('-ndoall: turns on limited nested DOALL support');
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
  else if StrToUpper(ParamStr(i)) = '-LOG' then TranscriptDisabled := false
  else if StrToUpper(ParamStr(i)) = '-VLOG' then begin TranscriptDisabled := false; Verbose := true; end
  else if StrToUpper(ParamStr(i)) = '-D' then DiagnosticsEnabled := true
  else if StrToUpper(ParamStr(i)) = '-NOMALUVA' then MaluvaDisabled := true
  else if StrToUpper(ParamStr(i)) = '-NDOALL' then NestedDoallEnabled := true
  else if StrToUpper(ParamStr(i)) = '-S' then SVGAMode := true
  else if StrToUpper(ParamStr(i)) = '-EXEC' then ExecExterns := true
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
    if (not loadCharset('DAAD.FNT')) then
      if (not loadLegacyCharset('DAAD.CHR')) then 
       Error(6, 'Neither DAAD.FNT nor DAAD.CHR were found.');

    InitTranscript('pcdaad.log');
    if Verbose then 
    begin
      TranscriptPas('PCDAAD Log ' + VERSION + #13);
      TranscriptPas('DDB Lang: ');
      if IsSpanish then TranscriptPas('Spanish'#13)
                  else TranscriptPas('English'#13);

      if DiagnosticsEnabled then TranscriptPas('Diagnostics enabled.'#13);
      if MaluvaDisabled then TranscriptPas('Maluva emulation disabled.'#13);
      if useOrderInputFile then TranscriptPas('Order Input file: '+orderInputFileName+#13);
    end;  
                     
    
    InitOrderFile;
    
    Randomize;        {Initialize the random generator}
    startVideoMode;   {Set the proper video mode}
    InitializeParser; {Initializes the parser}
    resetFlags;       {Restores flags initial value}
    resetObjects;     {Restore objects to "initially at" locations}
    resetWindows;     {clears all windows setup}
    resetStack;
    resetProcesses;
    InitializePCX(SVGAMode); {Initializes pictures buffer}
    if loadPCX(65535, SVGAMode) then  {Load intro screen if present}
    begin
      DisplayPCX(0,0,320,200,0, SVGAMode); {Paint the picture}
      ReadKey;
      DisplayPCX(0,0,0,0,1, SVGAMode); {Clear the PCX Window}
    end; 
    
    run; {there is no way back from this procedure, so cleaning isn't here}
end.
