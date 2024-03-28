{$I SETTINGS.INC}
{$F+}
{All the DSP SFX stuff. Brought from old NMP}
unit SFX;

{
    Flag FSOUND is used to control SFX playing:
    Bit 0: 1 = SFX engine enabled 
    Bit 1: 1 = OPL engine enabled 
    Bit 2: 1 = SFX plays in loop mode
    Bit 3: 1 = OPL plays in loop mode
    Bit 4: 1 = SFX is playing
    Bit 5: 1 = OPL is playing
}


interface



var SoundBlasterFound: boolean; {True if a SoundBlaster is found}
    SBBasePort, SBIRQ, SBDMA : Word; { SoundBlaster configuration}
    
    
{Initializes the sound system}
procedure InitializeSFX; 

{Terminates the sound system}
procedure TerminateSFX; 

{Plays SFX file

@param SampleNumber: Number of the SFX file to play. i.e. 4 will play 004.SFX
@param Loop: If true, the SFX will play in and endless loop mode
@param MySampleRate: If different from 0, the SFX will play at this sample rate.
 If 0, the sample rate will be the one stored in the SFX file
}
procedure PlaySFX(SampleNumber : byte; Loop:boolean; MySampleRate : Word); 

{Stops the loop mode, if active, meaning the SFX being played, if any, will stop when the current loop ends}
procedure StopSFXLoop;




implementation

uses dos, flags, ibmpc, utils, log;

var SFXPtr : Pointer; { Pointer to the sample data in RAM }
    CurrentSampleRate: Byte; {Rate to play the SFX}

    RemainingSize, SizeToPlay: Word; {Remaining size of the SFX to play by the IRQ
                                      handler, and size to play in the next DMA transfer}
    TotalSize: Word; {Total size of the SFX sample data currently in RAM}

    RemainingPTR: Pointer; {Pointer to the next data to play within the sample data}
    
    OldIRQVector: Pointer; {Old IRQ vector, to be restored on termination}
    OldPort21: Byte; {Same for port 21h}
    
 


(* Writes value to the DSP *)
procedure WriteDSP(value : Byte);
begin
  WHILE Port[SBBasePort + $C] AND $80 <> 0 DO;
  Port[SBBasePort + $C] := Value;
end;

(* Reads value from the DSP *)
function ReadDSP : byte;
BEGIN
  WHILE Port[SBBasePort + $0E] and $80 = 0 do;
  ReadDSP := Port[SBBasePort + $0A];
END;

(* Reads the DSP version *)
function DSPVersion: String;
var minor : byte;
BEGIN
 WriteDSP($E1);
 DSPVersion := IntToStr(ReadDSP) + '.' + inttostr(ReadDSP);
END;

(* Resets the DSP at specific port and returns true if successful*)
function ResetDSP(BasePort : word) : boolean;
var InitialTicks, CurrentTicks: Word;
begin
 Port[BasePort + $6] := 1;
 Delay(0.10);
 Port[BasePort + $6] := 0;
 Delay(0.10);
 InitialTicks := getTicks;
 repeat
  currentTicks := getTicks;
  if (currentTicks<getTicks) then currentTicks := currentTicks and $10000;
 until ((currentTicks - initialTicks) / 18.2 >= 0.5) OR (Port[BasePort + $E] AND $80 = $80);
 if (Port[BasePort + $E] AND $80 <> $80) then ResetDSP := false
 else if (Port[BasePort + $A] = $AA) then ResetDSP := true
 else ResetDSP := false;
end;




(* Prepares the DMA to play a sample *)
procedure PrepareDMA(SamplePTR: Pointer; SampleSize: Word);
var Page: Byte;
    Offset: Word;
begin
    Offset := Seg(SamplePTR^) SHL 4 + Ofs(SamplePTR^);
    Page := (Seg(SamplePTR^) + Ofs(SamplePTR^) shr 4) SHR 12;
    Port[$0A] := 5;
    Port[$0C] := 0;
    Port[$0B] := $49;
    Port[$02] := Lo(Offset);
    Port[$02] := Hi(Offset);
    Port[$83] := page;
    Port[$03] := Lo(SampleSize);
    Port[$03] := Hi(SampleSize);
    Port[$0A] := 1;
  
end;

{ Called when a sample has been player by the DMA chip. It will check if there's more data to play, and if so, it 
 will prepare the DMA chip to play it. Also, if loop is active, it will "rewind" the sample and play it again}
procedure IRQHandler; interrupt;
var value: Byte;
    Offset: Word;
    Page: Byte;
begin
 dec(RemainingSize, SizeToPlay);
 inc(longint(RemainingPTR),SizeToPlay);
 value:= Port[SBBasePort + $E];  

 { If there's RemainingSize data, play it, also if there's no RemainingSize data but the loop flag is set, play it as well }
 IF (RemainingSize <> 0) OR  ((getFlag(FSOUND) AND $04) = $04) then 
  begin
   if RemainingSize = 0  then 
   begin { Rewind }
    RemainingPTR:= SFXPtr;
    RemainingSize:= TotalSize
   end;

   if RemainingSize > 16384 then SizeToPlay:=16384
                            else SizeToPlay:=RemainingSize;
                        
    (* DMA chip setup *)
{    PrepareDMA(RemainingPTR, SizeToPlay);}
    Offset := Seg(RemainingPTR^) SHL 4 + Ofs(RemainingPTR^);
    Page := (Seg(RemainingPTR^) + Ofs(RemainingPTR^) SHR 4) SHR 12;
    Port[$0A] := 5;
    Port[$0C] := 0;
    Port[$0B] := $49;
    Port[$02] := Lo(offset);
    Port[$02] := Hi(offset);
    Port[$83] := page;
    Port[$03] := Lo(RemainingSize);
    Port[$03] := Hi(RemainingSize);
    Port[$0A] := 1;
    WriteDSP($40);
    WriteDSP(CurrentSampleRate);
    (* Set the playback type (8-bit) *)
    WriteDSP($14);
    WriteDSP(Lo(RemainingSize));
    WriteDSP(Hi(RemainingSize));
  end
  else setFlag(FSOUND, getFlag(FSOUND) AND $EB); (* clear SFX playing flag  and loop flag*)
  Port[$20]:=$20; {PIC_EOI = 0x20, End-of-interrupt command code}
end;




function GetBlaster(var IRQ, DMA:Word): boolean;
var S:String;
    S2:String[10];
    Code:Integer;
begin
 GetBlaster:= false;
 S:= GetEnv('BLASTER');
 IF S='' then Exit;
 S:=S+' ';
 S2:=Copy(S,Pos('I',S)+1,255);
 S2:=Copy(S2,1,Pos(' ',S2)-1);
 VAL(S2,IRQ,Code);
 S2:=Copy(S,Pos('D',S)+1,255);
 S2:=Copy(S2,1,Pos(' ',S2)-1);
 VAL(S2,DMA,Code);
 GetBlaster:=True;
end;

procedure InitializeDSP;
begin
 ASM
  IN AL,021h
  MOV OldPort21,AL
  MOV CX,SBIRQ
  MOV AH,0FEh
  ROL AH,CL
  AND AL,AH
  OUT 021h,AL
 end;
 GetIntVec(8 + SBIRQ, OldIRQVector);
 SetIntVec(8 + SBIRQ, @IRQHandler);
 ResetDSP(SBBasePort);
 WriteDSP($D1); {Speaker ON}
end;

{Tries to find a soundBlaster in ports $210 to $240}
function FindSoundBlaster: boolean;
var Aux: boolean;
begin
 SBBasePort := $210;
 WHILE (SBBasePort <= $240) DO
  BEGIN
   Aux := ResetDSP(SBBasePort);
   IF Aux THEN
    begin
     FindSoundBlaster := true;
     exit;
    END;
   SBBasePort := SBBasePort + $10;
  END;
  SBBasePort := 0;
  FindSoundBlaster := false;
END;





(***************************************************************** PUBLIC FUNCTIONS ***********************************)

procedure PlaySFX(SampleNumber: Byte; Loop: Boolean; MySampleRate: Word);
var  Page, Offset : word;
     SampleFile: file;
     SampleFileName: string;
     SizeToPlay: Word;
     ID:String[23];
begin
  if not SoundBlasterFound then Exit;
 
  (* Read the SFX file and initialize CurrentSampleRate*)
  SampleFileName := IntToStr(SampleNumber);
  while (length(SampleFileName)<3) do SampleFileName := '0' + SampleFileName;
  Assign(SampleFile, SampleFileName + '.SFX');
  Reset(SampleFile, 1);
  if (ioresult<>0) then Exit; {Silently fail if file not found}
  IF SFXPtr<>NIL THEN FreeMem(SFXPtr, TotalSize); {Free previous SFX data if any}

  BlockRead(SampleFile, ID, 24); (* Evitar ID *)
  BlockRead(SampleFile, TotalSize, 2);
  BlockRead(SampleFile, CurrentSampleRate, 1); 
  if (MySampleRate <> 0) then CurrentSampleRate := MySampleRate; 
  
  GetMem(SFXPtr,TotalSize);
  BlockRead(SampleFile,SFXPtr^,TotalSize);
  Close(SampleFile);
 
  (* Initiliaze global vars used later by the IRQ handler *)
  RemainingPTR := SFXPtr;
  RemainingSize := TotalSize;

  (* Set FSOUND flag values*)
  setFlag(FSOUND, getFlag(FSOUND) OR $10); (* Set SFX playing flag *)
  if Loop then setFlag(FSOUND, getFlag(FSOUND) OR $04)  (* Set SFX loop flag *)
          else setFlag(FSOUND, getFlag(FSOUND) AND $FB); (* Clear SFX loop flag *)


  (* Maximum size to play in one go via DMA is 16K *)
  IF RemainingSize > 16384 then SizeToPlay:=16384
                           else SizeToPlay := RemainingSize;
                             
  
  (* Prepare DMA *)
  PrepareDMA(SFXPtr, SizeToPlay);
  
  (* Set the playback frequency *)
  WriteDSP($40);
  WriteDSP(CurrentSampleRate);
  (* Set the playback type (8-bit) *)
  WriteDSP($14);
  WriteDSP(Lo(SizeToPlay));
  WriteDSP(Hi(SizeToPlay));
end;



procedure InitializeSFX;
begin
    SoundBlasterFound := FindSoundBlaster;

    SFXPtr := nil;
    if not SoundBlasterFound then Exit;
    if (not GetBlaster(SBIRQ, SBDMA)) then
    begin
        SBIRQ := 5; {Most common configuration}
        SBDMA := 1;
    end;
    InitializeDSP;

    (* Set the SFX bits in the FSOUND flag *)
    setFlag(FSOUND, getFlag(FSOUND) AND $EB); (* Clear bits for SFX is playing and loop mode *)
    if SoundBlasterFound then setFlag(FSOUND, getFlag(FSOUND) OR $01) (* Set SFX engine enabled flag *)
                            else setFlag(FSOUND, getFlag(FSOUND) AND $FE); (* Clear SFX engine enabled flag *)

end;

procedure StopSFXLoop;
begin
    if not SoundBlasterFound then Exit;
    setFlag(FSOUND, getFlag(FSOUND) AND $FB); (* clear SFX loop flag *)
end;

procedure TerminateSFX;
begin
 if not SoundBlasterFound then Exit;
 SetIntVec(8+SBIRQ,OldIRQVector);
 ASM
  MOV AL,OldPort21
  OUT 021h,AL
 end;
 WriteDSP($D3); {Speaker Off};
end;


begin
 SoundBlasterFound := false;
end.