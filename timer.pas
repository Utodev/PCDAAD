unit timer;


interface

procedure SetTimer(frequency : word);
procedure CleanUpTimer;

implementation

uses dos, adlib;

const TIMERINTR = 8;
      PIT_FREQ = $1234DD;
      TIMERFreq : Word = 19;

VAR BIOSTimerHandler : procedure;
    clock_ticks, counter : longint;
    SYSTIME: longint;

{$F+}
procedure TimerHandler; interrupt;
begin
   {Take care of OPL music}
   if ActiveMusic then ProcessDRO;

  {Standard timer handler  code}
  clock_ticks := clock_ticks + counter;
  if clock_ticks >= $10000 then
    begin
      Inc(SysTime);
      clock_ticks := clock_ticks - $10000;
      asm pushf end;
      BIOSTimerHandler;
    end
  else Port[$20] := $20; { Tells the interrupt controler we are done processing the handler. It's not called in the
                          other part of the if/else structure because the BIOS default timer handler will do it}
END; 
{$F-}


procedure SetTimer(frequency : word);
begin
  clock_ticks := 0;
  counter := PIT_FREQ div frequency;

  GetIntVec(TIMERINTR, @BIOSTimerHandler);
  SetIntVec(TIMERINTR, @TimerHandler);

  Port[$43] := $34;
  Port[$40] := counter mod 256;
  Port[$40] := counter div 256;
  TimerFreq:=Frequency;
end;

procedure CleanUpTimer;
begin
  { Restore the normal clock frequency }
  Port[$43] := $34;
  Port[$40] := 0;
  Port[$40] := 0;
  { Restore the normal ticker handler }
  SetIntVec(TIMERINTR, @BIOSTimerHandler);
end;

end.