unit errors;

interface

uses utils;

procedure error(level: word; message: string );

implementation

uses ibmpc, global;

procedure error(level: word; message: string );
begin
    terminateVideoMode;
    CopyRight;
    Writeln('[Runtime Error: ' , strpad(inttostr(level), '0', 3) , '] - ' , message,'.');
    halt(level);
end;

end.