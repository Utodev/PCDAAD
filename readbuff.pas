{$I SETTINGS.INC}
unit READBUFF;

(* This units implements a buffer able to read a file in blocks, which avoids
a slower reading byte by byte. It has been created to read the larger SVGA
PCX files, but it can be used for any other purpose. *)


interface


var 
    bufferFileSize: longint;

function fileGetByte(offset: longint):byte;
function fileGetWord(offset: longint):word;
function fileopen(Filename: string):boolean;
procedure fileclose;

implementation

uses log, utils;

const BUFFER_SIZE = 32768;

type TReadBuffer = array[0..BUFFER_SIZE-1] of byte;

var f: file;
    buffer: ^TReadBuffer;
    bufferCurrentoffset: longint;

function fileopen(Filename: string):boolean;
var aux : boolean;
var BytesRead: word;
begin
    Assign(f, Filename);
    Reset(f, 1);
    aux := IOresult = 0;
    if not aux then bufferFileSize := 0 else
    begin
     bufferFileSize := FileSize(f);   
     getmem(buffer, BUFFER_SIZE);
     BlockRead(f, buffer^, BUFFER_SIZE, BytesRead);
     bufferCurrentoffset := 0;
    end; 
    fileopen := aux;
end;

function fileGetByte(offset: longint):byte;
var BytesRead: word;
begin

    if (offset < bufferCurrentoffset) or (offset >= bufferCurrentoffset + BUFFER_SIZE) then 
    begin
        Seek(f, offset);
        BlockRead(f, buffer^, BUFFER_SIZE, BytesRead);
        bufferCurrentoffset := offset;
    end;
    fileGetByte := buffer^[offset - bufferCurrentoffset];
end;

function fileGetWord(offset: longint):word;
begin
    fileGetWord := fileGetByte(offset) + (fileGetByte(offset + 1) shl 8);
end;

procedure fileclose;
begin
 FreeMem(buffer, BUFFER_SIZE);
 Close(f);
end;

begin
 bufferFileSize := 0;
end.