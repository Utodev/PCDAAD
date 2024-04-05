{$I SETTINGS.INC}

unit charset;

interface

type TCharsetData = array [0..2047] of byte;

var charsetWidth : array [0..255] of byte;


    charsetData: ^TCharsetData;

function loadCharset(filename : String): boolean;
function loadLegacyCharset(filename: String): boolean;

implementation

    
function loadCharset(filename : String): boolean;
var charsetFile : file;
    bytesRead: longint;
begin
    loadCharset := false;
    Assign(charsetFile, filename);
    Reset(charsetFile, 1);
    if (ioresult = 0) then
    begin
        Seek(charsetFile, filesize(charsetFile) - 256*9);
        BlockRead(charsetFile, charsetWidth, sizeof(charsetWidth));
        BlockRead(charsetFile, charsetData^, sizeof(TCharsetData));
        Close(charsetFile);
        loadCharset := true;
    end;
end;

function loadLegacyCharset(filename: String): boolean;
var charsetFile : file;
    bytesRead: longint;
    var i : Byte;
begin
    loadLegacyCharset := false;
    Assign(charsetFile, filename);
    Reset(charsetFile, 1);
    if (ioresult = 0) then
    begin
        BlockRead(charsetFile, charsetData^, sizeof(TcharsetData));
        Close(charsetFile);
        for i:= 0 to 255 do charsetWidth[i] := 6;
        loadLegacyCharset := true;
    end;
end;


begin
    new(charsetData);
end.
