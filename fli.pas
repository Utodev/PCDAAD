unit fli;

{$I settings.inc}
{$G+} 
(*   Overrides general setting, as using FLI  requires a 286  *)
(*   Note: there is a $G- at the end of this unit.                                    *)


interface

procedure PlayFLI(FLINumber: Byte; Loop : Boolean);

implementation

uses palette, utils, ibmpc, log;

    
    

procedure UNPACK_LC(var buffer); Assembler;
ASM
 PUSH DS
 CLD
 LDS SI,[buffer]
 MOV AX,0A000h
 MOV ES,AX
 LODSW          (* Load Skip *)
 MOV DX,AX
 LODSW          (* Load lines to change *)
 MOV CX,AX
 @BUC_LINE:
 PUSH CX

 (* Caculate initial position of line,  320 x SKIP *)

 MOV DI,DX
 SHL DI,8   (* DI contains SKIP * 256 *)
 MOV AX,DX
 SHL AX,6   (* AX contains SKIP * 64 *)
 ADD DI,AX  (* DI contains SKIP * 64 + SKIP * 256 = SKIP x (64+256) = SKIP * 320 *)
            (* Faster than MUL or IMUL *)
 LODSB      (* Read number of packets *)
 OR AL,AL
 JZ @NoPackets
 XOR CH,CH
 MOV CL,AL      (* Put them in CX *)
 @packetsLoop:
 PUSH CX
 LODSW          (* Read SkipCOunt and  Size_Count (AL y AH respec.) *)
 MOV BX,AX
 XOR BH,BH
 ADD DI,BX      (* Skip SkipCount bytes *)

 (* Now let's check if Size_Count > 0 *)

 MOV BL,AH
 AND BL,080h    (* if is larger, it has frist bit set to 1*)
 JZ @IsGreater

 @IsLess:

 MOV CX,0100h
 SHR AX,8
 SUB CX,AX      (* Size_Count = 256 - byte(SizeCount) *)
 LODSB          (* Load value to store  *)
 REP STOSB
 JMP @Cont

 @IsGreater:
 XOR CX,CX
 MOV CL,AH
 REP MOVSB

 @Cont:
 POP CX
 LOOP @packetsLoop
 @NoPackets:
 POP CX
 INC DX
 LOOP @BUC_LINE
 POP DS
end;

procedure UNPACK_RUN(var buffer); Assembler;
ASM
 PUSH DS
 CLD
 LDS SI,[buffer]
 MOV AX,0A000h
 MOV ES,AX
 XOR BX,BX
 XOR DX,DX      (* Skip=0 *)
 MOV CX,200     (* Lines to change = 200 *)

 @BUC_LINE:
 PUSH CX

 (* Calculate initial position of the line,  320 x SKIP *)

 MOV DI,DX
 SHL DI,8   (* DI contains now SKIPx256 *)
 MOV AX,DX
 SHL AX,6   (* AX contains now SKIPx64  *)
 ADD DI,AX  (* DI contains now SKIP x 64 + SKIP x 256 = SKIP x (64+256)= SKIP * 320 *)
            (* This is faster than  MUL o IMUL *)

 LODSB      (* Read number of packets *)
 OR AL,AL
 JZ @NoPackets
 XOR CH,CH
 MOV CL,AL      (* Put them in CX *)
 @packetsLoop:
 PUSH CX
 LODSB          (* Size_Count (AL) *)

 (* CHeck if Size_Count ei >0 *)

 MOV BL,AL
 AND BL,080h    (* If is greater than 0, first bit is 1 *)
 JZ @IsGreater

 @IsLess:

 MOV CX,0100h
 MOV BL,AL
 SUB CX,BX      (* Size_Count:=256-byte(SizeCount) *)
 REP MOVSB
 JMP @Cont

 @IsGreater:
 XOR CX,CX
 MOV CL,AL
 LODSB
 REP STOSB

 @Cont:
 POP CX
 LOOP @packetsLoop
 @NoPackets:
 POP CX
 INC DX
 LOOP @BUC_LINE
 POP DS
end;

procedure PlayFLI(FliNumber: Byte; Loop:Boolean);

var FirstFrame:Byte;
    ChunkOffset : Longint;
    W: Word;
    FLIFileName : String;
    iFrame, iChunk: Word;
    Playing: Boolean;
    CurrentFrameOffset: LongInt;
    FLIFileHandler :file;
    FirstFrameOffset: LongInt;

    var FLIHeader : record
                    Size:LongInt; {Size of entire file.}
                    Magic: word; {File-format identifier.  Always hex AF12 for .FLC; AF11 for .FLI files.}
                    Frames: word; {Number of frames in flic.}
                    Width, Height: word; {Screen width and height in pixels.}
                    PixelDepth: word; {Bits per pixel (always 8).}
                    Flags: word;
                    Speed: word;
                    Next,Frit: Longint;
                    Expand: array[0..101] of Byte;
                 end;

    var FrameHeader : record
                        Size: LongInt; {Size of frame chunk, including subchunks and this header.}
                        Magic: word;  {Prefix chunk identifier.  Always hex F1FA.}
                        Chunks: word; {Number of subchunks.}
                        Expand: array [1..8] OF Byte;
                      end;

    var ChunkHeader : record
                        Size:Longint;
                        ChunkType: Word
                      end;


    procedure R_FLI_COLOR;
    var Packets: Word;
        i: Word;
        Count:Byte;
        CountWord: Word;
        InitialColor:Byte;
        PacketData : Word;
    begin
        Blockread(FLIFileHandler,Packets,2);
        TranscriptPas('FLI_COLOR found. Reading ' + IntToStr(Packets) + ' packets' + #13);
        for i := 1 TO Packets do
        begin
            Blockread(FLIFileHandler,PacketData,2);
            InitialColor:= Lo(PacketData);
            Count:= Hi(PacketData);
            if Count = 0 then CountWord := 256
                         else CountWord := Count;
            TranscriptPas('Color ' + IntToStr(PacketData SHR 8) + ' Count ' + IntToStr(CountWord) + #13);
            LoadPaletteFromFile(FLIFileHandler, InitialColor, CountWord);
        end;
        SetAllPaletteDirect;
    end;

    procedure R_FLI_BLACK;
    begin
        FillChar(mem[$a000:0], 64000, 0);
    end;

    function R_FLI_LC:Boolean;
    var PTR:Pointer;
    begin
        if MaxAvail < ChunkHeader.Size - SizeOf(ChunkHeader) then 
        begin
            R_FLI_LC := false;
            Exit
        end 
        else R_FLI_LC := true;

        GetMem(PTR, ChunkHeader.Size - SizeOf(ChunkHeader));
        Blockread(FLIFileHandler,PTR^, ChunkHeader.Size - SizeOf(ChunkHeader));
        UNPACK_LC(PTR^);
        FreeMem(PTR, ChunkHeader.Size - 6);
    end;

    function R_FLI_BRUN:Boolean;
    var PTR:Pointer;
    begin
        TranscriptPas('Reading FLI_BRUN: ' + 'MaxAvail ' + IntToStr(MaxAvail) +
         ' ChunkHeader.Size ' + IntToStr(ChunkHeader.Size) + #13);
        if MaxAvail < ChunkHeader.Size - 6  then 
        begin
            TranscriptPas('Not enough memory to read FLI_BRUN' + #13);
            R_FLI_BRUN := false;
            Exit
        end
        else R_FLI_BRUN := true;

        GetMem(PTR, ChunkHeader.Size-6);
        Blockread(FLIFileHandler, PTR^, ChunkHeader.Size - 6);
        UNPACK_RUN(PTR^);
        FreeMem(PTR,ChunkHeader.Size-6);
    end;

    procedure R_FLI_COPY;
    begin
      TranscriptPas('Reading FLI_COPY' + #13);
      Blockread(FLIFileHandler,mem[$a000:0],64000);
    end;

VAR SaveSVGAMode: boolean;

    

begin
    FLIFileName := IntToStr(FliNumber);
    while (length(FLIFileName)<3) do FLIFileName := '0' + FLIFileName;
    FLIFileName := FLIFileName + '.FLI';
    Assign(FLIFileHandler, FLIFileName);
    Reset(FLIFileHandler, 1);
    if (ioresult <> 0) then Exit; {Silently fail if file not found}  
    
    FirstFrame:=1;

    Blockread(FLIFileHandler,FLIHeader,SizeOf(FLIHeader));
    
    Playing := true;

    
    if (FLIHeader.Magic <> $AF11) then
    begin
        TranscriptPas('FLI file ' + FLIFileName + ' doesn''t have FLI signature.' + #13);
        Close(FLIFileHandler);
        Exit;
    end;

    if (FLIHeader.Width <> 320) or (FLIHeader.Height <> 200) then    
    begin
        TranscriptPas('FLI file ' + FLIFileName + ' is not 320x200' + #13);
        Close(FLIFileHandler);
        Exit;
    end;


    SaveSVGAMode := SVGAMode;
    if (SVGAMode) then
    begin
        SVGAMode := false;
        startVideoMode;
    end;
    SVGAMode := SaveSVGAMode;

    while(Playing) do
    begin
        FirstFrameOffset:=Filepos(FLIFileHandler);
        for iFrame := FirstFrame TO FLIHeader.Frames  do
        begin
            CurrentFrameOffset := Filepos(FLIFileHandler);
            Blockread(FLIFileHandler, FrameHeader, SizeOf(FrameHeader));
            for iChunk := 1 to FrameHeader.Chunks do
            begin
                ChunkOffset := FilePos(FLIFileHandler);
                Blockread(FLIFileHandler,ChunkHeader,SizeoF(ChunkHeader));
                case ChunkHeader.ChunkType of
                    11 : R_FLI_COLOR;
                    12 : if not R_FLI_LC then 
                            begin
                                TranscriptPas('Not enough memory to run FLI file ' + FLIFileName + #13);
                                Close(FLIFileHandler);
                                if (SVGAMode) then startVideoMode;
                                Exit
                            end;                            
                    13 : R_FLI_BLACK;
                    15 : if not R_FLI_BRUN then 
                            begin
                                TranscriptPas('Not enough memory to run FLI file ' + FLIFileName + #13);
                                Close(FLIFileHandler);
                                if (SVGAMode) then startVideoMode;
                                Exit
                            end;
                    16 : R_FLI_COPY;
                end; {case}
                Seek(FLIFileHandler, ChunkOffset + ChunkHeader.Size);
                if Keypressed  then 
                begin
                    readkey;
                    Close(FLIFileHandler);
                    if (SVGAMode) then startVideoMode;
                    Exit;
                end;
            end;
            Delay(1/70 * FLIHeader.Speed);
            
            Seek(FLIFileHandler, CurrentFrameOffset + FrameHeader.Size);
        end;
        {Terminated, check if we need to rewind}
        if Loop then Seek(FLIFileHandler, FirstFrameOffset)
                else Playing := false;
    end;     {While playing}          
    if (SVGAMode) then startVideoMode;
    Close(FLIFileHandler);
end;

end.
{$G-}
