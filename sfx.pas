{$I SETTINGS.INC}
{$F+}
{All the DSP SFX stuff. Brought from old NMP}
{Please notice the 8-bit auto-init DMA mode is used, which is only available in the SoundBlaster 2.0
 and above. SoundBlaster 1.0 won't sound, and FSOUND flag value may be inaccurate.}
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

const BUFFER_SIZE = 2048;

type Buffers =array[0..1] OF array[0..BUFFER_SIZE-1] of byte;      

var SFXPtr : Pointer; { Pointer to the sample data in RAM }
    CurrentSampleRate: Byte; {Rate to play the SFX}

    SFXTotalSize: Word; {Total size of the SFX sample data currently in RAM}

    
    OldIRQVector: Pointer; {Old IRQ vector, to be restored on termination}
    OldPort21: Byte; {Same for port 21h}

    BufferOrder : Byte; {Which of the two buffers is currently being played}
    BufferOffset : Word; {current offset in the current sample data}
    Buffer:^Buffers; {The buffers}
    ActiveSample : boolean; {whether a sample is currently being played or not}  
                            {Please notice I could use the FSOUND flag to check this
                            but I prefer to have a separate variable because the 
                            author may modify the flag and mess up the SFX engine}
    Offset, Page : Word; {Offset and page of the double buffer}

    
 


(* Writes value to the DSP *)
procedure WriteDSP(value : Byte);
begin
  WHILE Port[SBBasePort + $C] AND $80 <> 0 DO;
  Port[SBBasePort + $C] := Value;
end;

(* Reads value from the DSP *)
function ReadDSP : byte;
begin
  WHILE Port[SBBasePort + $0E] and $80 = 0 do;
  ReadDSP := Port[SBBasePort + $0A];
end;

(* Reads the DSP version *)
function DSPVersion: String;
var minor : byte;
begin
 WriteDSP($E1);
 DSPVersion := IntToStr(ReadDSP) + '.' + inttostr(ReadDSP);
end;

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



{ Called when a sample has been player by the DMA chip. It will check if there's more data to play, and if so, it 
 will prepare more data in the buffer for the DMA chip to send. Also, if loop is active, it will "rewind" the sample 
 and play it again}
procedure IRQHandler; interrupt;
var Value: Byte;
begin
    TranscriptPas('IRQHandler'#13);
    if ActiveSample then
    begin
      TranscriptPas('ActiveSample'#13);
      {Check if the current block is the last one}
      if BufferOffset + BUFFER_SIZE >  SFXTotalSize  then
      begin
        TranscriptPas('Last Block'#13);
        if (getFlag(FSOUND) AND $04) = $04 then {If threre's a loop active...}
        begin
            TranscriptPas('Loop'#13);
            {put the remaining data in the buffer}
            move(pointer(longint(sfxPtr) + bufferoffset)^,Buffer^[BufferOrder],SFXTotalSize - BufferOffset); 
            {fill the rest of the buffer with the beginning of the sample}
            move(sfxPtr^,Buffer^[BufferOrder][SFXTotalSize-BufferOffset],BUFFER_SIZE - SFXTotalSize + BufferOffset);
            {Set new buffer offset}
            BufferOffset:=BUFFER_SIZE - SFXTotalSize + BufferOffset;
        end
        else
        begin
            TranscriptPas('Not Loop'#13);
            {put the remaining data in the buffer}
            move(pointer(longint(sfxPtr) + bufferoffset)^,Buffer^[BufferOrder], SFXTotalSize - BufferOffset);
            {fill the rest of the buffer with zeroes (silence)}
            FillChar(Buffer^[BufferOrder][SFXTotalSize - BufferOffset],BUFFER_SIZE - SFXTotalSize + BufferOffset, 0);
            {Mark the sample as played}
            ActiveSample:=False;
        end;

      end
      else {If it's not the last sample data}
      begin
        TranscriptPas('Not last'#13);
        {Move a whole buffer}
        move(pointer(longint(sfxPtr)+bufferoffset)^,Buffer^[BufferOrder],BUFFER_SIZE);
        {Move the offset}
        BufferOffset := BufferOffset + BUFFER_SIZE;
      end;
     end
     else {If there's no sample being played} 
     begin
        TranscriptPas('Completed'#13);
        {Fill both buffers with silence}
        FillChar(Buffer^,SizeOf(Buffers),0);
        {Mark as finished}
        setFlag(FSOUND, getFlag(FSOUND) AND $EB); (* clear SFX playing flag  and loop flag*)
     end;
  
    
    {ACK interrupt to DSP}
    value:= Port[SBBasePort + $E];  

    {Switch buffers}
    BufferOrder:=BufferOrder XOR 1;
    {Mark interrupt as handled}
    Port[$20]:=$20;



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

procedure Speaker(OnOff: Boolean);
begin
 if OnOff then WriteDSP($D1) else WriteDSP($D3);
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
 Speaker(true); {Speaker ON}
 
end;

{Tries to find a soundBlaster in ports $210 to $240}
function FindSoundBlaster: boolean;
var Aux: boolean;
begin
 SBBasePort := $210;
 WHILE (SBBasePort <= $260) DO
  begin
   Aux := ResetDSP(SBBasePort);
   IF Aux THEN
    begin
     FindSoundBlaster := true;
     exit;
    end;
   SBBasePort := SBBasePort + $10;
  end;
  SBBasePort := 0;
  FindSoundBlaster := false;
end;





(***************************************************************** PUBLIC FUNCTIONS ***********************************)

procedure PlaySFX(SampleNumber: Byte; Loop: Boolean; MySampleRate: Word);
var  SampleFile: file;
     SampleFileName: string;
     PageRegister: Byte;
begin
    if not SoundBlasterFound then Exit;

    (* Read the SFX file and initialize CurrentSampleRate*)
    SampleFileName := IntToStr(SampleNumber);
    while (length(SampleFileName)<3) do SampleFileName := '0' + SampleFileName;
    Assign(SampleFile, SampleFileName + '.SFX');
    Reset(SampleFile, 1);
    if (ioresult<>0) then Exit; {Silently fail if file not found}
    IF SFXPtr<>NIL THEN FreeMem(SFXPtr, SFXTotalSize); {Free previous SFX data if any}

    Seek(SampleFile,24); (* Avoid ID in the header *)
    BlockRead(SampleFile, SFXTotalSize, 2);
    BlockRead(SampleFile, CurrentSampleRate, 1); 
    if (MySampleRate <> 0) then CurrentSampleRate := MySampleRate; 

    GetMem(SFXPtr,SFXTotalSize);
    BlockRead(SampleFile,SFXPtr^,SFXTotalSize);
    Close(SampleFile);

    TranscriptPas('Playing SFX with a size of ' + IntToStr(SFXTotalSize) + ' bytes'#13);


    {Prepare both buffers first}
    BufferOrder := 0;
    Fillchar(Buffer^,BUFFER_SIZE*2,0);
    
    if (SFXTotalSize < BUFFER_SIZE * 2) then 
    begin
        Move(SFXPtr^, Buffer^, SFXTotalSize); (* Fill up as much as possible *)
        BufferOffset := SFXTotalSize;
    end
    else
    begin
        Move(SFXPtr^, Buffer^, BUFFER_SIZE * 2); (* Fill up both buffers *)
        BufferOffset := BUFFER_SIZE * 2;
    end;
    
    TranscriptPas('DMA Setup. DMA channel: ' + IntToStr(SBDMA) + ' IRQ: ' +
     IntToStr(SBIRQ) + 'BasePort' + IntToStr(SBBasePort) +     
      ' Offset: ' + IntToStr(Offset) + ' Page: ' + IntToStr(Page) +
      ' Buffer Size: ' + IntToStr(BUFFER_SIZE) + ' CurrentSampleRate: ' + IntToStr(CurrentSampleRate) + #13);
    (* Prepare DMA *)
    Port[$0A] := 4 + SBDMA; 
    Port[$0C] := 0;
    Port[$0B] := $58 + SBDMA; {0101=>single, enable initialization  | 10xx write - , xx = DMA channel}
    Port[$01 + SBDMA] := Lo(Offset);
    Port[$01 + SBDMA] := Hi(Offset);
    case SBDMA of
        0: PageRegister := $87;
        1: PageRegister := $83;
        2: PageRegister := $81;
        3: PageRegister := $82;
    end;
    Port[PageRegister] := Page;
    Port[$01 + 2 * SBDMA] := Lo(2 * BUFFER_SIZE - 1); {Size of the two buffers -1 (according DMA specs) }
    Port[$01 + 2 * SBDMA] := Hi(2 * BUFFER_SIZE - 1);
    Port[$0A] := SBDMA; {Select DMA channel}

    TranscriptPas('Start Playing'#13);
    WriteDSP($40);  {playback frequency}
    WriteDSP(CurrentSampleRate);
    WriteDSP($48); {Set DMA Block Size}
    WriteDSP(Lo(BUFFER_SIZE - 1));
    WriteDSP(Hi(BUFFER_SIZE - 1));
    WriteDSP($1C); {playback type 8-bit auto-init DMA mode }
    WriteDSP(Lo(BUFFER_SIZE)); {DSP command 1C expects number of bytes to play - 1}
    WriteDSP(Hi(BUFFER_SIZE));
        
    (* Set FSOUND flag values*)
    setFlag(FSOUND, getFlag(FSOUND) OR $10); (* Set SFX playing flag *)
    if Loop then setFlag(FSOUND, getFlag(FSOUND) OR $04)  (* Set SFX loop flag *)
            else setFlag(FSOUND, getFlag(FSOUND) AND $FB); (* Clear SFX loop flag *)
    ActiveSample := true;

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
 Speaker(false); {Speaker Off};
 SetIntVec(8 + SBIRQ, OldIRQVector);
 if (SFXPtr<>NIL) then FreeMem(SFXPtr,SFXTotalSize);
 ASM
  MOV AL,OldPort21
  OUT 021h,AL
 end;
end;


procedure GetPageMem(VAR P:Pointer;Size:Word);
(* Obtains a memory area that is within the same page *)
var Offset : Word;
    Aux : Pointer;
begin
 GetMem(P,Size);
 Offset := Seg(P^) SHL 4 + Ofs(Buffer);
 if Offset + Size > 65535 then begin
                                GetMem(Aux,Size);
                                FreeMem(P,Size);
                                P:=Aux
                               end;
end;


begin
 SoundBlasterFound := false;
 ActiveSample := false;
 GetPageMem(pointer(Buffer),SizeOf(Buffers));
 Offset := Seg(Buffer^) SHL 4 + Ofs(Buffer^);
 Page := (Seg(Buffer^) + Ofs(Buffer^) SHR 4) SHR 12;
end.