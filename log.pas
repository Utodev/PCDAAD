{$i settings.inc}

unit log;

interface

uses strings;

function InitTranscript(Filename: String): boolean;
procedure Transcript(LogText: Pchar); {Transcript a Pchar string}
procedure TranscriptPas(LogText: String); {Transcript a classic pascal string}
procedure CloseTranscript;

var TranscriptDisabled: boolean;
    Verbose: boolean;
    ImmediateLogFLush: boolean;

implementation

uses errors;

var TranscriptFile: text;
    TranscriptUnit : String;


function InitTranscript(Filename: String): boolean;
begin
    if not TranscriptDisabled  then
    begin
        Assign(TranscriptFile, Filename);
        Rewrite(TranscriptFile);
        if (ioresult<>0) then Error(7, 'Unable to create transcript file');
        if (ImmediateLogFLush) then Close(TranscriptFile);
    end;
end;

procedure Transcript(LogText: Pchar);
begin
    if not TranscriptDisabled then
    begin
        if (ImmediateLogFLush) then Append(TranscriptFile);
        Write(TranscriptFile, LogText);
        if (ioresult<>0) then Error(8, 'Unable to write transcript file');
        if (ImmediateLogFLush) then  Close(TranscriptFile);
    end;
end;

procedure TranscriptPas(LogText: String);
begin
    if not TranscriptDisabled then
    begin
        if (ImmediateLogFLush) then Append(TranscriptFile);
        Write(TranscriptFile, LogText);
        if (ioresult<>0) then Error(8, 'Unable to write transcript file');
        if (ImmediateLogFLush) then Close(TranscriptFile);
    end;
end;

procedure CloseTranscript;
begin
 if not TranscriptDisabled and not ImmediateLogFLush then Close(TranscriptFile);
end;

begin
    TranscriptDisabled := true;
    (* Check to never do transcript on floppy disk *)
    TranscriptUnit := ParamStr(0);
    TranscriptUnit :=  Upcase(TranscriptUnit[1]);
    Verbose := false;
    if (TranscriptUnit='A') or (TranscriptUnit='B') then TranscriptDisabled := true;
    ImmediateLogFLush := false;
end.
