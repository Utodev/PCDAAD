{$I SETTINGS.INC}

(* This unit implements the condacts created by MALUVA extension for DAAD : XMES and XPART. Rest of
Maluva condacts are not appliable or not necessary, which includes XMESSAGE that actualy never
reaches the DDB file, as it's replaced by XMES + a carriage return by DRC compiler.
*)

unit MALUVA;

interface

procedure Xmes(offset: word);

procedure Xpart(part: Byte);


var MaluvaDisabled : boolean;

implementation

uses errors, ibmpc, utils, ddb, messages;

var ActivePart : Byte;


(* This function requires explanation: to print a xmessage we would need to load it in RAM,
   what I did with a BlockRead in the "buffer" variable, as Xmessages are 511 chars long
   maximum (plus one byte for the ending zero). Sadly, after doing that I realized that
   all the code made to print messages was reading directly from the DDB in RAM, char by 
   char. Reading the message from a memory address outside the area where the DDB file is 
   stored was not possible without huge refactoring. I could also have made a pararell 
   function to print Xmessages, but that was awful for manteinance. Another option would
   have been converting the DDB unit in a OOP unit, where DDB is an object so I can have
   two different ones, but I wanted to keep PCDAAD as an old style program, without OOP.

   Thus, I decided to make a patch, somehow related on Maluva does to print XMessages. This
   code does the following:

   1) Loads 512 bytes from the offset specified in the XMB file.
   2) Copies 512 bytes from the address in the DDB memory area where
     the first system message is located to preserve them
   3) Copies the Xmessage over those 512 bytes in the DDB
   4) Prints the system message 0 (currently overwritten by the message)
   5) Restores the 512 bytes preserved

   That way the normal code that prints messages, prints xmessages as well, it's easy
   to mantain as there is no two pieces of code doing the same, there is no OOP and
   no refactoring was needed. A little old 8-bit style? Yes, but hey, no other
   8bit developer did ever write shuch a long comment explaining why and how, did them?

   Oh! Of course I could actually have used any location in the DDB file, but patching at the System 
   Messages area makes sure there will be 512 bytes there without overwriting other necessary areas.
   Remember a xmessage can have underscores that may need to access the object texts, fon instance.

*)
procedure Xmes(offset: word);
var buffer : array[0..511] of char;
    backup : array[0..511] of char;
    XmessageFile: file;
    ReadBytes : Word;
begin
 Assign(XmessageFile, IntToStr(ActivePart) + '.XMB');
 Reset(XmessageFile,1);
 if (ioresult<>0) then Error(20, 'Xmessage file not found');
 Seek(XmessageFile, offset);
 BlockRead(XmessageFile, Buffer, 511, ReadBytes);
 {Preserve 512 bytes at the sysmess messages area in the DDB }
 MoveFromDDB(backup,getWord(DDBHeader.sysmessPos), 512);
 {Move the Xmessage to the Sysmess Area}
 MoveToDDB(buffer,getWord(DDBHeader.sysmessPos), 512);
 {Print the message}
 WriteText(getPcharMessage(DDBHeader.sysmessPos, 0), false);   
 {restore the backup}
 MoveToDDB(backup,getWord(DDBHeader.sysmessPos), 512);
 Close(XmessageFile);
end;

procedure Xpart(part: Byte);
begin
 ActivePart := part;
end;


begin
 ActivePart := 0;
 MaluvaDisabled := false;
end. 


