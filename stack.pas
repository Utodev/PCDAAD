{$I SETTINGS.INC}
(* Implements the processes call stack*)

unit Stack;

interface
uses global;

const MAX_PROCESS_STACK = 500;
      
type TStackElement = record
                        ProcessPTR, EntryPTR, CondactPTR, DoallPTR, DoallEntryPTR, DoallFlag, DoallLocation : Word;

                     end;

var ProcessStack : array [0..MAX_PROCESS_STACK-1] of TStackElement;
    StackPTR : Word;


procedure StackPop;
procedure StackPush;
procedure resetStack;

implementation

uses errors, ddb, graph, flags;

procedure resetStack;   
begin
    StackPTR := 0;
end;    

procedure StackPop;
var StackElement: TStackElement;
begin
    {if POP and nothing to POP we have come to the end of process 0, just exit}
    if StackPTR = 0 then begin
                           terminateVideoMode; 
                           WriteLn('Goodbye.');
                           halt(0);
                          end;

    StackPtr := StackPtr - 1;
    StackElement := ProcessStack[StackPtr];
    ProcessPTR := StackElement.ProcessPTR;
    EntryPTR := StackElement.EntryPTR;
    CondactPTR := StackElement.CondactPTR;
    DoallPTR := StackElement.DoallPTR;
    DoallEntryPTR := StackElement.DoallEntryPTR;
    DoallLocation := StackElement.DoallLocation;
    setFlag(FDOALL, StackElement.DoallFlag);
end;

procedure StackPush;
var StackElement: TStackElement;    
begin
    if (StackPTR = MAX_PROCESS_STACK - 1) then Error(2, 'Stack overflow. Too many nested processes');
    StackElement.ProcessPTR := ProcessPTR;
    StackElement.EntryPTR := EntryPTR;
    StackElement.CondactPTR := CondactPTR;
    StackElement.DoallPTR := DoallPTR;
    StackElement.DoallEntryPTR := DoallEntryPTR;
    StackElement.DoallFlag := getFlag(FDOALL);
    StackElement.DoallLocation := DoallLocation;
    ProcessStack[StackPtr] := StackElement;
    StackPtr := StackPtr + 1;
end;


begin
    StackPTR := 0;
end.

