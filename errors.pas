unit errors;

interface

uses utils;

procedure error(level: word; message: string );

implementation

uses ibmpc;

procedure error(level: word; message: string );
begin
    terminateVideoMode;
    Writeln('[Runtime Error: ' , strpad(inttostr(level), '0', 3) , '] - ' , message,'.');
    halt(level);
end;

end.