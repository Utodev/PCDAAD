{$i settings.inc}

unit log;

interface

uses strings;

function InitTranscript(Filename: String): boolean;
procedure Transcript(LogText: Pchar); {Transcript a Pchar string}
procedure TranscriptPas(LogText: String); {Transcript a classic pascal string}

implementation

uses errors;

var TranscriptFile: text;


function InitTranscript(Filename: String): boolean;
begin
    Assign(TranscriptFile, Filename);
    Rewrite(TranscriptFile);
    if (ioresult<>0) then Error(7, 'Unable to create transcript file');
    Close(TranscriptFile);
end;

procedure Transcript(LogText: Pchar);
begin
    Append(TranscriptFile);
    Write(TranscriptFile, LogText);
    if (ioresult<>0) then Error(8, 'Unable to write transcript file');
    Close(TranscriptFile);
end;

procedure TranscriptPas(LogText: String);
begin
    Append(TranscriptFile);
    Write(TranscriptFile, LogText);
    if (ioresult<>0) then Error(8, 'Unable to write transcript file');
    Close(TranscriptFile);
end;


end.
