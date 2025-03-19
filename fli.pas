unit fli;

{$I settings.inc}
{$G+} 
(*   Overrides general setting, as using FLI  requires a 286  *)
(*   Note: there is a $G- at the end of this unit.                                    *)

{
    Original information about FLI format published by Jim Kent, author
    of Autodesk Animator, in Dr. Dobb's Journal, March 1993
    https://jacobfilipp.com/DrDobbs/articles/DDJ/1993/9303/9303a/9303a.htm   
}


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


(*


Overview of File Structure
The key idea behind flic delta compression is simple: You only store the parts of the picture that change from frame to frame. This helps make the file much smaller than if each frame had to be stored completely. Delta compression also makes it possible to quickly display a flic, even on a relatively slow display device, since only the parts of the screen that are changing need to be updated. Flic files use a simple-minded, run-length compression scheme on the bits of the picture that do change from frame to frame. The entire first frame is stored run-length compressed as well. Figure 1(a) shows an overview of the file structure.

Figure 1:(a) Overview of the flic-file stucture; (b)flic-file hierarchy of chunks.

  (a)

  file header
  optional prefix chunk
  first frame (run-length compressed)
  second frame (delta compressed)
          ...
  nth frame (delta compressed)
  ring frame (delta between nth frame and first)

(b)

  Flic chunk (includes header and rest of file)
     prefix chunk (in .FLC files only)
        settings chunk (Animator Pro private area)
          position chunk (Offset of cel into screen)
     frame 1 chunk
          postage stamp (icon first frame, .FLC only)
          color data (256 colors)
          pixel data (normally run length encoded)
     frame 2 chunk
          color data (only colors that change)
          pixel data (delta encoded)
...
     ring frame chunk
          color data (only colors that change)
          pixel data (delta encoded)

The flic includes the ring frame so the flic can be played repeatedly without a perceptible pause between the last frame and the first. This is necessary since unpacking the first frame (which is run-length compressed) is generally much slower than updating the screen from a delta.

Flic files are structured in a hierarchy of chunks. A chunk contains the size of itself, a type, and some data peculiar to whatever type of chunk it is. The hierarchy in a flic is three levels deep, as shown in Figure 1(b). The advantage of the chunk structure is that new types of chunks can be added to the file format without breaking existing flic readers. A flic player simply skips over chunks it does not understand or is not interested in.

Reading a Flic
To read a flic, first open the file, read in the 128-byte flic header (see Table 1), and check that the type field has an appropriate number. If the type field indicates it is an .FLI file, convert the speed field from 1/70th to 1/1000th of a second. If it's an .FLC file, seek to the first frame position as defined by the oframe1 field of the header. You can then read in a 16-byte frame header (see Tables 2 and 3). It's good to check the type field here, as well, and report an error if it doesn't match hexadecimal F1FA. The size of the data portion of the frame will vary. You can allocate buffer space according to the size field of the header minus 16 (since the size field includes the size of the header) and read the rest of the frame into the buffer. To decode the data in the buffer, loop through each chunk, dispatching the ones you recognize to routines specific to that chunk type. Table 4 lists the chunk types that occur inside a frame.

Table 1: Flic header structure (128 bytes). Fields marked .FLC only are set to 0 in an .FLI.

  Offset   Size   Name     Description

    0      4      size     Size of entire file.
    4      2      type     File-format identifier.  Always hex
                           AF12 for .FLC; AF11 for .FLI files.
    6      2      frames   Number of frames in flic.
    8      2      width    Screen width in pixels.
   10      2      height   Screen height in pixels.
   12      2      depth    Bits per pixel (always 8).
   14      2      flags    Set to hex 0003.
   16      4      speed    Time delay between frames.  For .FLI
                           files, in units of 1/70 second; for .FLC,
                           in milliseconds.
   22      4      created  MS-DOS-formatted date and time of
                           file's creation (.FLC only).
   26      4      creator  Animator Pro sets this to serial number
                           of copy of program that created flic.
                           Safe to set to 0 and ignore (.FLC only).
   30      4      updated  MS-DOS-formatted date and time of
                           file's most recent update (.FLC only).
   34      4      updater  Serial number of program that last
                           up-dated file.  See creator (.FLC only).
   38      2      aspectx  X-axis aspect ratio of display where file
                           was created.  A rectangle of dimensions
                           aspectx by aspecty will appear square.
                           For 320x200 display, aspect ratio is
                           6:5.  For most other displays, 1:1.
                           (.FLC only).
   40      2      aspecty  Y-axis aspect ratio of flic (.FLC only).
   42     38      reserved Set to 0.
   80      4      oframe 1 Offset from beginning of file to first frame
                           (.FLC only).
   84      4      oframe 2 Offset from beginning of file to second
                           frame (.FLC only).
   88     40      reserved Set to 0.


Table 2: Prefix header structure (16 bytes). Most programs just seek over the prefix chunk if it is present.

Offset  Size  Name     Description

   0     4   size      Size of prefix chunk, including subchunks.
   4     2   type      Prefix chunk identifier.  Always hex F100.
   6     2   chunks    Number of subchunks.
   8     8   reserved  Set to 0.


Table 3: Frame header structure (16 bytes).

Offset  Size  Name      Description

   0     4    size      Size of frame chunk, including subchunks
                        and this header.
   4     2    type      Prefix chunk identifier.  Always hex F1FA.
   6     2    chunks    Number of subchunks.
   8     8    reserved  Set to 0.


Table 4: Frame subchunk types.

Value  Name       Description

   4   COLOR_256  256-level color palette information (.FLC
                  only).
   7   DELTA_FLC  Delta compression (.FLC only).
  11   COLOR_64   64-level color pallete information (.FLI only).
  12   DELTA_FLI  Delta compression (.FLI only).
  13   BLACK      Entire frame set to color 0.
  15   BYTE_RUN   Byte run-length compression (first frame).
  16   LITERAL    Uncompressed pixels.
  18   PSTAMP     Miniature image of flic for visual file
                  requestor.  First frame only, safe to ignore.

                  Decoding Chunk Types
There are a variety of different chunk types, and understanding how to decode them is central to writing flic-supported programs. The file READFLIC.C (Listing One , page 92) presents routines that read and decompress a flic. The routines assume Intel byte ordering, but are otherwise fairly portable. The file starts with the low-level decompression routines: first for colors, then for pixels. It then goes to the higher-level exported flic_xxxx routines as prototyped in READFLIC.H (Listing Two, page 96). The program requires other files, such as those that attend to machine-specific details. Because of their length, these files and an executable version of the program are available only electronically; see "Availability," page 5. In this section, I'll describe in detail the available chunk types.

Chunk Type 16 (FLI_COPY). No compression. This chunk contains an uncompressed image of the frame. The number of pixels following the chunk header is exactly the width of the animation times its height. The data starts in the upper-left corner with pixels copied from left to right and then top to bottom. Chunk 16 is created when the preferred compression method generates more data than the uncompressed frame image--a relatively rare situation.

Chunk Type 13 (BLACK). No data. This chunk has no data following the header. All pixels in the frame are set to color-index 0.

Chunk Type 15 (BYTE_RUN). Byte run-length compression. This chunk contains the entire image in a compressed format. Usually this chunk is used in the first frame of an animation, or within a postage-stamp image chunk.

The data is organized in lines. Each line contains packets of compressed pixels. The first line is at the top of the animation, followed by subsequent lines moving downward. The number of lines in this chunk is given by the height of the animation. The first byte of each line is a count of packets in the line. This value is ignored--it is a holdover from the original Animator. It is possible to generate more than 255 packets on a line. The width of the animation is now used to drive the decoding of packets on a line; continue reading and processing packets until width pixels have been processed, then proceed to the next line.

Each packet consist of a type/size byte, followed by one or more pixels. If the packet type is negative, it is a count of pixels to be copied from the packet to the animation image. If the packet type is positive, it contains a single pixel that is to be replicated; the absolute value of the packet type is the number of times the pixel is to be replicated.

Chunk Type 12 (DELTA_FLI). Byte-oriented delta compression. This chunk contains the differences between the previous frame and this frame. This compression method was used by the original Animator, but is not created by Animator Pro. This type of chunk can appear in an Animator Pro file, however, if the file was originally created by Animator and some (but not all) frames were modified using Animator Pro.

The first 16-bit word following the chunk header contains the position of the first line in the chunk. This is a count of lines (down from the top of the image) unchanged from the prior frame. The second 16-bit word contains the number of lines in the chunk. The data for the lines follows these two words. Each line begins with two bytes. The first byte of each line contains the number of packets for the line. Unlike BRUN compression, the packet count is significant (because this compression method is only used on 32Ox2OO flics).

Each packet consists of a single-byte column skip, followed by a packet type/size byte. If the packet type is positive, it is a count of pixels to be copied from the packet to the animation image. If the packet type is negative, it contains a single pixel which is to be replicated; the absolute value of the packet type gives the number of times the pixel is to be replicated. (The negative/positive meaning of the packet-type bytes in DELTA_FLI compression is reversed from that used in BYTE_RUN compression. This gives better performance during playback.)

Chunk Type 7 (DELTA_FLC). Word-oriented delta compression. This format contains the differences between consecutive frames. This is the format most often used by Animator Pro for frames other than the first frame of an animation. It is similar to the byte-oriented delta (DELTA_FLI) compression, but is word oriented instead of byte oriented. The data is organized into lines, and each line is organized into packets.

The first word in the data following the chunk header contains the number of lines in the chunk. Each line can begin with some optional words that are used to skip lines and set the last byte in the line for animations with odd widths. These optional words are followed by a count of the packets in the line. The line count does not include skipped lines.

The high-order two bits of the word are used to determine the contents of the word, as shown in Table 5. The packets in each line are similar to the packets for the line-coded chunk. The first byte of each packet is a column-skip count. The second byte is a packet type. If the packet type is positive, the packet type is a count of words to be copied from the packet to the animation image. If the packet type is negative, the packet contains one more word which is to be replicated. The absolute value of the packet type gives the number of times the word is to be replicated. The high-and low-order byte in the replicated word do not necessarily have the same value.

Table 5: High-order two bits of the word determine the contents of the word.

Bit 15  Bit 14  Meaning

   0       0    Word contains packet count.  Packets follow this
                word.  Packet count can be 0; occurs when only
                last pixel on a line changes.

   1       0    Low-order byte is to be stored in the last byte of
                current line.  Packet count always follows this
                word.

   1       1    Word contains a line skip count.  Number of lines
                skipped is given by absolute value of word.
                Word can be followed by more skip counts, a
                last byte word, or packet count.

Chunk Type 4 (COLOR_256). 256-level color map. The data in this chunk is organized in packets. The first word following the chunk header is a count of the number of packets in the chunk. Each packet consists of a 1-byte color-index skip count, a 1-byte color count, and three bytes of color in formation for each color defined.

At the start of the chunk, the color index is assumed to be 0. Before processing any colors in a packet, the color-index skip count is added to the current color index. The number of colors defined in the packet is retrieved. A 0 in this byte indicates that 256 colors follow. The three bytes for each color define the red, green, and blue components of the color in that order. Each component can range from 0 (off) to 255 (full on). The data to change colors 2, 7, 8, and 9 would appear as in Example 1.

Example 1: Data to change colors 2, 7, 8, and 9.

   2                                ; two packets
   2, 1, r, g, b                    ; skip 2, change 1
   4, 3, r, g, b, r, g, b, r, g, b  ; skip 4, change 3

Chunk Type 11 (COLOR_64). 64-level color map. This chunk is identical to FLI_COLOR256 except that the values for the red, green, and blue components are in the range of 0-63 instead of 0-255.


Limitations and Conclusions
In the worst case, the Animator will currently produce first frames that are 7102+width * height bytes and subsequent frames that are 802+width * height bytes. Fortunately, in most cases, significant image compression is possible for hand-drawn and computer-synthesized imagery. Digitized video imagery does not compress well with the simple lossless run-length delta-compression schemes used in a flic. Frames of objects moving against a solid dark background may compress significantly even if taken from video; but lighter-colored backgrounds often contain enough noise on the video signal to foil the flic compression scheme even if the camera isn't moving. Still, for those of us lacking MPEG hardware, flics are one of the best ways of storing and displaying moving digital imagery on our computers.




*)