(* Implements the processes call stack*)

unit Stack;

interface
uses global;

const MAX_PROCESS_STACK = 500;
      

var ProcessStack : array [0..MAX_PROCESS_STACK-1] of Word;
    StackPTR : Word;


function StackPop: Word;
procedure StackPusb(ptr: word);
procedure resetStack;

implementation

uses errors;

procedure resetStack;
begin
    StackPTR := 0;
end;    

function StackPop: Word;
begin
    if StackPTR = 0 then Error(2, 'Stack pop without push');
    StackPop := ProcessStack[StackPTR];
    StackPtr := StackPtr - 1;
end;

procedure StackPusb(ptr: word);
begin
    if (StackPTR = MAX_PROCESS_STACK - 1) then Error(2, 'Stack overflow');
    ProcessStack[StackPtr] := ptr;
    StackPtr := StackPtr + 1;
end;


begin
    StackPTR := 0;
end.

