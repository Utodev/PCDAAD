(*
    This interpreter is (C) Uto (Carlos Sánchez) and is distributed under the MIT license.

    The code has been built with Borland Pascal 7.0, although it's likely to work fine 
    with Turbo Pascal 7.0 and Turbo pascal 6.0

*)

{$I SETTINGS.INC}
{$DEFINE VGA}           {Keep this DEFINE for VGA output, remove for simple text output}

program PCDAAD;

uses global, ddb, strings , errors, stack, condacts, flags, objects, graph;

var ddbFilename : String;

var  Indirection, ValidEntry :  boolean;
     Opcode : TOpcodeType;
     i, j : integer;



begin
    Writeln('PC DAAD Interpreter ',version,' (C) Uto 2021');
    if (ParamCount>0) then ddbFilename := ParamStr(1) else ddbFilename := 'DAAD.DDB';
    if (not loadDDB(ddbFilename)) then Error(1, 'DDB file not found or invalid.');
    Randomize;      {Initialize the random generator}
    startVideoMode;
    while (true) do {Main Loop}
    begin
        resetFlags;     {Restore flags initial value}
        resetObjects;   {Restore objects to "initially at" locations}
        resetWindows;   {redefine all windows}
        resetProcesses;
        resetStack;
        while (true) do
        begin
            if (getByte(EntryPTR) <> END_OF_PROCESS_MARK)  then
            begin
                ValidEntry := ((getByte(EntryPTR) = getFlag(FVERB)) OR (getByte(EntryPTR) = NO_WORD))
                            and
                            ((getByte(EntryPTR+1) = getFlag(FNOUN)) OR (getByte(EntryPTR+1) = NO_WORD));

                CondactPTR := getWord(EntryPTR + 2);
            end
            else
            begin
                CondactPTR := StackPop;
            end;

            if ValidEntry then 
            begin
                condactResult := true;
                while (getByte(CondactPTR) <> END_OF_CONDACTS_MARK) and condactResult do
                begin
                    opcode := getByte(CondactPTR);
                    if (opcode AND $80 <> 0) then
                    begin
                      Indirection := true;
                      opcode := opcode AND $7F;
                    end
                    else Indirection := false;
                    if (condactTable[opcode].numParams>0) then
                    begin
                        CondactPTR := CondactPTR + 1;
                        Parameter1 := getByte(CondactPTR);
                        if Indirection then parameter1 := getFlag(Parameter1);
                        if (condactTable[opcode].numParams>1) then
                        begin
                            CondactPTR := CondactPTR + 1;
                            Parameter2 := getByte(CondactPTR);
                        end;
                    end;
                    condactResult := true;
                    condactTable[opcode].condactRoutine; {Execute the condact}
                    (* FALTA VER QUE HACEMOS AQUI SI condactResult es false *)
                    CondactPTR := CondactPTR + 1;
                end;
            end;

        end;
    end;
end.
