unit timer;


interface

var SystemTimeMilliseconds: longint;

procedure SetTimer;
procedure CleanUpTimer;

implementation

uses dos, adlib, palette;

const TIMERINTR = 8;
      PIT_FREQ = $1234DD;

VAR BIOSTimerHandler : procedure;
    clock_ticks, counter : longint;

   
    
    

{$F+}
procedure TimerHandler; interrupt;
begin
   Inc(SystemTimeMilliseconds);
   {Take care of OPL music}
   if ActiveMusic then ProcessDRO;

   if ColorCyclingActive then
     begin
       Inc(colorCycleCounter);
       if colorCycleCounter >= colorCycleFrames then
         begin
           colorCycleCounter := 0;
           RotatePalette(ColorCyclingStartColour, ColorCyclingEndColour); 
         end;
     end;

  {Standard timer handler  code}
  clock_ticks := clock_ticks + counter;
  if clock_ticks >= $10000 then
    begin
      clock_ticks := clock_ticks - $10000;
      asm pushf end;
      BIOSTimerHandler;
    end
  else Port[$20] := $20; { Tells the interrupt controler we are done processing the handler. It's not called in the
                          other part of the if/else structure because the BIOS default timer handler will do it}
END; 
{$F-}


procedure SetTimer;
begin
  clock_ticks := 0;

  counter := PIT_FREQ div 1000;
  SystemTimeMilliseconds := 0;

  GetIntVec(TIMERINTR, @BIOSTimerHandler);
  SetIntVec(TIMERINTR, @TimerHandler);

  Port[$43] := $34;
  Port[$40] := counter mod 256;
  Port[$40] := counter div 256;
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