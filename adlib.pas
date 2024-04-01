UNIT adlib;

{$I SETTINGS.INC}

{This unit is used to play DRO 2.0 files on an Adlib card. 
 Specs for DRO 2.0 files can be found at https://moddingwiki.shikadi.net/wiki/DRO_Format#Version_2.0.
 *********************************************************************************************************
 Contents of that page regarding DROP 2.0 have been more or less copied as a comment 
 at the end of this file.
 *********************************************************************************************************
 The PlayDRO procedure just sets up the music to be played, but the actual playing is done by the
 ProcessDRO procedure, which must be called by an interrup routine every 1 ms.

{$F+}
interface

{
    Flag FSOUND is used to control SFX playing:
    Bit 0: 1 = SFX engine enabled 
    Bit 1: 1 = OPL engine enabled 
    Bit 2: 1 = SFX plays in loop mode
    Bit 3: 1 = OPL plays in loop mode
    Bit 4: 1 = SFX is playing
    Bit 5: 1 = OPL is playing
}


var AdlibFound, ActiveMusic : Boolean; 

procedure InitializeAdlib;
procedure WriteAdlib(Reg:Byte;Value:Byte; BasePort: Word);
procedure TerminateAdlib;
procedure PlayDRO(MelodyNumber : byte; Loop:boolean); 
procedure StopDRO;
procedure ProcessDRO;

implementation


uses flags, ibmpc, utils, log, sfx;

type TMusicBuffer = array[0..65534] of Byte;
     THardwareType = (OPL2, DualOPL2, OPL3);



var MusicPTR: ^TMusicBuffer;
    MusicSize: Word;
    BufferOffset: Word;
    DelayInMilliseconds: Word;
    iShortDelayCode: Byte;
    iLongDelayCode: Byte;
    CurrentCommand: Longint;
    OPLPort: Word;
    iHardwareType : THardwareType;


procedure WriteAdlib(Reg:Byte;Value:Byte; BasePort: Word); Assembler;
ASM
 MOV DX, BasePort
 MOV AL,Reg
 OUT DX,AL
 MOV CX,6
@Loop1:
 IN AL,DX
 DEC CX
 JNZ @Loop1
 MOV AL,Value
 INC DX
 OUT DX,AL
 DEC DX
 MOV CX,35
@Loop2:
 IN AL,DX
 DEC CX
 JNZ @Loop2
end;

function FindAdlib:Boolean;
var A,B:Byte;
begin
 WriteAdlib(4,$60, OPLPort);
 WriteAdlib(4,$80, OPLPort);
 A:=Port[$388];
 WriteAdlib(2,$FF, OPLPort);
 WriteAdlib(4,$21, OPLPort);
 Delay(0.5);
 B:=Port[$388];
 WriteAdlib(4,$60, OPLPort);
 WriteAdlib(4,$80, OPLPort);
 A:=A AND $E0;
 B:=B AND $E0;
 FindAdlib:=(A=0) AND (b=$c0);
end;


procedure InitializeAdlib;
var i: byte;
begin
    setFlag(FSOUND, getFlag(FSOUND) AND $D5);   (* Clear all bits for OPL *)
    AdlibFound := FindAdlib;
    if (AdlibFound) then
    begin
        TranscriptPas('Adlib or compatible card found.' + #13#10);
        {Initiliaze Adlib}
        WriteAdlib($1,0, OPLPort);
        WriteAdlib($BD,$C0, OPLPort);    
        
        (* Set OPL engine enabled flag *)
        setFlag(FSOUND, getFlag(FSOUND) OR $02);

    end; 

end;


procedure ProcessDRO; 
var command: byte;
    data: byte;
    port: byte;
begin
    if not AdlibFound then Exit;


    dec(DelayInMilliseconds);

    while (DelayInMilliseconds = 0) do {Run as much commands as possible until another delay is found}
    begin      
        if (BufferOffset >= MusicSize) then
        begin
            if (getFlag(FSOUND) AND $08 = $08) then {Loopmode}
            begin
                BufferOffset := 12 + 14 + MusicPTR^[25]; {rewind but skip the header and code map table}
            end
            else 
            begin
                StopDRO;
                Exit;
            end;    
        end;

        {TranscriptPas(IntToStr(CurrentCommand) + '> ');}
        CurrentCommand := CurrentCommand + 1;

        command := MusicPTR^[BufferOffset];
        data := MusicPTR^[BufferOffset + 1];
        BufferOffset := BufferOffset + 2;
        
        if (command = iShortDelayCode) then 
        begin
            {Delay is in milliseconds -1, so 0 means 1 millisecond, 1 means 2, etc.}
            DelayInMilliseconds := data  + 1; 
            {TranscriptPas('DLYS => ' + IntToStr(DelayInMilliseconds) +  #13#10);}
        end    
        else
        if (command = iLongDelayCode)  then
        begin
            {Delay is in milliseconds -1, so 0 means 1 millisecond, 1 means 2, etc.}
            DelayInMilliseconds := (data+1) SHL 8; {Long delay is in 256 ms units (also +1 first)}
            {TranscriptPas('DLYL => ' + IntToStr(DelayInMilliseconds) +  #13#10);}
        end
        else 
        begin
            {For the time being, Dual OPL2 or OPL3 is not supported, so we skip any command refering to that}
            Port := MusicPTR^[12 + 14 + (command AND $7F)];
            
            { If we don't have a SoundBlaster, we can only use OPL2 from the Adlib card, so we ignore the 
            second OPL2 chip and do our best to play with just one. Also, if the melody is for OPL2, not
            dual, we send data only to Adlib port as it doesn't matter}
            if (iHardwareType = OPL2) or (NOT SoundBlasterFound) then
            BEGIN
                if (command and $80 <> $80) then WriteAdlib(port, data, $388); 
            END
            ELSE
            BEGIN {Otherwise, we have a SoundBlaster, try to send by channel}
                if (command and $80 <> $80) then WriteAdlib(port, data, OPLPort)
                else WriteAdlib(port, data, OPLPort + 2);                
            END;
            {TranscriptPas(IntToHex(Port) + ' => ' + IntToHex(data) + #13#10);}
        end;

    end;          
end;
{
COSAS:
    - Cuando termina se quedan las últimas notas sonando, habrá que silenciar o hacer un fade OUT
}
procedure PlayDRO(MelodyNumber : byte; Loop:boolean); 
var MusicFile: file;
    MusicFileName: string;
    
begin
    if not AdlibFound then Exit;
    if ActiveMusic then Exit; {If there's a music being played, ignore this request}

    (* Read the DRO file and initialize CurrentSampleRate*)
    MusicFileName := IntToStr(MelodyNumber);
    while (length(MusicFileName)<3) do MusicFileName := '0' + MusicFileName;
    Assign(MusicFile, MusicFileName + '.DRO');
    Reset(MusicFile, 1);
    MusicSize := FileSize(MusicFile);
    if (ioresult<>0) then Exit; {Silently fail if file not found}
    IF MusicPTR <> nil then FreeMem(MusicPTR, MusicSize); {Free previous SFX data if any}
    GetMem(Pointer(MusicPTR),MusicSize);
    BlockRead(MusicFile,MusicPTR^,MusicSize);
    Close(MusicFile);
    
    if (MusicPTR^[8] <> 2) then Exit; {Invalid DRO file, not a version 2 DROP file}

    iHardwareType := THardwareType(MusicPTR^[20]);
    iShortDelayCode := MusicPTR^[23];
    iLongDelayCode := MusicPTR^[24];
    

    BufferOffset := 12 + 14 + MusicPTR^[25]; {Skip the header and the Code map} 

    
    SetFlag(FSOUND, getFlag(FSOUND) OR $20); {Set Adlib is playing flag}
    if Loop then SetFlag(FSOUND, getFlag(FSOUND) OR  $08) {Set Adlib loop flag}
            else SetFlag(FSOUND, getFlag(FSOUND) AND $F7); {Clear Adlib loop flag}
    {Run the firsts commands until first delay. This is becaus usually DRO files start
    with all the instruments setup, and that may be too much OUTs in one single 
    interrupt call. Just being paranoid, to be honest.}
    DelayInMilliseconds := 1;
    CurrentCommand := 0;
    ActiveMusic := true; {Don't move this over the ProcesDRO above or there may be overlapping}
end;

procedure StopDRO;
var i : integer;

begin
    if not AdlibFound then Exit;
    if not ActiveMusic then Exit; {If there's no music being played, ignore this request}
    ActiveMusic := false;

    {Silence all channels}
    for i :=$40 to $55 do WriteAdlib(i,$FF, OPLPort); 
    if (iHardwareType<>OPL2) and (SoundBlasterFound) then
    for i :=$40 to $55 do WriteAdlib(i,$FF, OPLPort+2); 

    {Clear Adlib is playing and loop flag}
    SetFlag(FSOUND, getFlag(FSOUND) AND $D7); 

end;

procedure TerminateAdlib;
begin
    if (AdlibFound) then
    begin
      if ActiveMusic then StopDRO;
      if MusicPTR<>NIL THEN FreeMem(MusicPTR, MusicSize); 
    end;     
end;




begin
    AdlibFound := false;
    ActiveMusic := false;   
    MusicPTR := NIL;
    OPLPort := $388;
    if (SoundBlasterFound) then OPLPort := SBBasePort;
end.

{
DRO 2.0 specs

HEADER
======
Data  type	            | Name	         | Description
BYTE[8]	                | cSignature	 | "DBRAWOPL" (not NULL-terminated)
UINT16LE	            | iVersionMajor	 | Version number (high)
UINT16LE	            | iVersionMinor	 | Version number (low)
UINT32LE	            | iLengthPairs	 | Length of the song in register/value pairs   
UINT32LE	            | iLengthMS	     | Length of the song data ("chunk" -?) in milliseconds
UINT8	                | iHardwareType	 | Flag listing the hardware used in the song
UINT8	                | iFormat	     | Data arrangement
UINT8	                | iCompression	 | Compression type, zero means no compression (currently only zero is used)
UINT8	                | iShortDelayCode| Command code for short delay (1-256ms)
UINT8	                | iLongDelayCode | Command code for short delay (> 256ms)
UINT8	                | iCodemapLength | Number of entries in codemap table
UINT8[iCodemapLength]	| iCodemap       | Codemap table (see below)

iHardwareType |	Description
    0         |	OPL2
    1	      | Dual OPL2
    2         |	OPL3

iFormat	| Description
0	    | Commands and data are interleaved (default/as per v1.0)
1	    | Maybe all commands, followed by all data (unused? - TODO: Confirm)

Notes:


- The iShortDelayCode value must have one added to it, as per v1.0 (so a short delay 
   of 2 == a 3ms delay)
- The iLongDelayCode value must have one added to it, then be multiplied by 256 (or "<< 8"), so
   a long delay of 2 == a 768ms delay
- Because the high bit in each codeword is used to refer to the second OPL2 chip (or the second 
  set of registers in an OPL3), there are only 128 possible codewords (0-127). Therefore
  iCodemapLength must always be 128 or less.DOSBox dumps a snapshot of the current register state 
  at the beginning of a capture. (Any other registers are assumed initialised to zero.)
  This means that even an OPL2 only song will appear to have some data sent to the second OPL chip, 
  because of this initial snapshot. To really know whether the second OPL chip is in 
  use, you can find out if it is actually making any sound, like so: Examine bit 5 (0x20) on
  registers 0xB0 to 0xB8. If this bit is set, a note is playing and the chip is being used.
- Check whether bitmask 0x1F on register 0xBD is greater than 0x10 (i.e. if (reg[0xBD] & 0x1F > 0x10) ...).
   If so, the chip is in percussive mode and a rhythm instrument is being played, so the chip is being used. 
  
  Codemap table
  
  The codemap table maps index numbers to OPL registers. As there are 256 possible OPL registers but only a 
  subset of these actually used, the mapping table allows up to 128 OPL registers to be used in a song. The
  other 128 (with the high bit set) are used for the second OPL2 chip in a dual-OPL2 capture.

  The table is a list of iCodemapLength bytes, with the index used later in the file. For example this code table:

  01 04 05 08 BD

  Means that when the song references register #0 the data should be sent to OPL register 0x01, when the song 
  references register #4 the data should go to OPL register 0xBD. If the song references register #128
  (i.e. register 128+0), data should be sent to OPL register 0x01 on the second chip (in dual OPL2 mode) or
  the second set of registers (OPL3 mode). Likewise register #132 (128+4) is OPL register 0xBD on the second chip.

}
