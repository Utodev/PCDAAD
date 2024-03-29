program wav2sfx;

{Important: please notice unlike the DAAD interpreter, this tool is to be compiled with Free pascal.}
{ It's a tool for modern OS like Windows, MacOS or Linux}
{$MODE OBJFPC}
{$I-}

uses sysutils;

CONST ID:String[24]='SFX File - NM Soft.'+#13+#10+#$1A;

type FileBuffer = array[0..65534] of Byte;    

var InFileName, OutFileName : String;
    InFile, OutFile : File;
    Buffer : ^FileBuffer;
    BufferSize : Longint;
    SampleRate : Longint;
    SampleLength : Longint;
    SampleLengthW :Word;
    SampleRateW : Word;
    SampleRateFinal : Byte;
   

procedure Syntax;
begin
    WriteLn('WAV2SFX converts 8 bit mono PCM WAV files into the SFX format used by PCDAAD.');
    WriteLn('Syntax: ');
    WriteLn('WAV2SFX <InFile> <OutFile>');
    Halt(0);
end;

procedure Error(Str: String);
begin
 Write('Error: ');
 Write(Str);
 WriteLn('.');
 Halt(1);
end; 

(* MAIN *)
begin
    if ParamCount <> 2 then Syntax;
    InFileName := ParamStr(1);
    OutFileName := ParamStr(2);

    if (NOT FileExists(InFileName)) then Error('Input file not found');

    Assign(InFile, InFileName);
    Reset(InFile, 1);
    BufferSize := filesize(InFile);
    
    if BufferSize> 65535 then Error('File too big to handle. Maximum size is 64Kb.');

    {Load the file in RAM}
    GetMem(Buffer, BufferSize);
    BlockRead(InFile, Buffer^, BufferSize);
    Close(InFile);

    {check if it has RIFF in the header}
    if (Buffer^[0]<>82) or (Buffer^[1]<>73) or (Buffer^[2]<>70) or (Buffer^[3]<>70) then Error('Invalid WAV file');    
    {check if it has WAVE in the header}
    if (Buffer^[8]<>87) or (Buffer^[9]<>65) or (Buffer^[10]<>86) or (Buffer^[11]<>69) then Error('Invalid WAV file');
    {check if it has fmt in the header}
    if (Buffer^[12]<>102) or (Buffer^[13]<>109) or (Buffer^[14]<>116) or (Buffer^[15]<>32) then Error('Invalid WAV file');
    {check if its pcm}
    if (Buffer^[20]<>1) or (Buffer^[21]<>0) then Error('Only PCM WAV files are supported');
    {check if it's mono}
    if (Buffer^[22]<>1) or (Buffer^[23]<>0) then Error('Only mono WAV files are supported');
    {check if it's 8 bit}
    if (Buffer^[34]<>8) or (Buffer^[35]<>0) then Error('Only 8 bit WAV files are supported');
    {check if "data" is at the right place}
    if (Buffer^[36]<>100) or (Buffer^[37]<>97) or (Buffer^[38]<>116) or (Buffer^[39]<>97) then Error('Invalid WAV file');

    SampleLength := Buffer^[40] + Buffer^[41] shl 8 + Buffer^[42] shl 16 + Buffer^[43] shl 24;
    if (SampleLength>65535-24-4) then Error('Sample too long for SFX format');
    SampleLengthW := SampleLength;

    SampleRate := Buffer^[24] + Buffer^[25] shl 8 + Buffer^[26] shl 16 + Buffer^[27] shl 24;
    SampleRateW := 65536 - round((256000000)/SampleRate);
    SampleRateFinal := Hi(SampleRateW);

    WriteLn('Sample length: ', SampleLengthW, ' bytes');
    WriteLn('Sample rate: ', SampleRate, ' Hz');
    WriteLn('Sample rate for SFX: ', SampleRateFinal, ' (', SampleRateW, ')');

    {Save the SFX file}
    Assign(OutFile, OutFileName);
    Rewrite(OutFile,1);
    if (ioresult<>0) then Error('Invalid output file');
    BlockWrite(OutFile,ID,24);
    BlockWrite(OutFile,SampleLengthW,2);
    BlockWrite(OutFile,SampleRateFinal,1);
    BlockWrite(OutFile,Buffer^[44],SampleLengthW);
    Close(Outfile);



     WriteLn('Done.');

end.

