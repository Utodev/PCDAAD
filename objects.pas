{$I SETTINGS.INC}
unit objects;


interface

uses global;

type TLocationType = byte;

const   NUM_OBJECTS = 256;
        MAX_OBJECT  = NUM_OBJECTS -1;
        NO_OBJECT = MAX_OBJECT;
        LOC_NOT_CREATED = 252;
        LOC_CARRIED = 254;
        LOC_WORN = 253;
      

function getObjectLocation(objno: word):TLocationType;
procedure setObjectLocation(objno: word; value: TLocationType);

{get the number of objects at location}
function getObjectCountAt(locno: TFlagType): TFlagType;

{Return weight of an object itself}
function getObjectWeight(objno: word): TFlagType;

{Returns tru if object is wearable}
function isObjectWearable(objno:TLocationType):boolean;

{Returns tru if object is a container}
function isObjectContainer(objno:TLocationType):boolean;

{Gets weight of object in depth if container}
function getObjectFullWeight(objno:TLocationType): TFlagType; 

{Sets the currently referenced object}
procedure SetReferencedObject(objno: TFlagtype); 

{Places the objects at their initial locations}
procedure resetObjects; 

{Makes a copy of object locations in RAM}
procedure RAMSaveObjects; 

{Restore a copy of object locations in RAM}
procedure RAMLoadObjects; 

{Finds object at location with that noun/adjective. If location = MAX_LOCATION any location matches}
function getObjectByVocabularyAtLocation(aNoun, anAdjective, location  :TFlagType): TFlagtype;

{gets next object at locno, starting by object objno. Use -1 to find first object, when no more objects
 the function returns MAX_OBJECT}                                                       
function getNextObjectAt(objno: integer; locno: TFlagType): TFlagType;

implementation

uses flags, ddb;

var objLocations: array [0..NUM_OBJECTS-1] of byte;
    objLocationsRAMSAVE: array [0..NUM_OBJECTS-1] of byte;

function getObjectCountAt(locno: TFlagType): TFlagType;
var i: word;
    count : TFlagType;
begin
 count := 0;
 for i := 0 to DDBHeader.numObj - 1 do 
  if (getObjectLocation(i)=locno) then count := count + 1;
 getObjectCountAt := count; 
end;


procedure RAMSaveObjects;
begin   
 move(objLocations, objLocationsRAMSAVE, sizeof(objLocations));
end; 

procedure RAMLoadObjects;
begin   
 move(objLocationsRAMSAVE, objLocations, sizeof(objLocations));
end; 

function getObjectWeight(objno: word): TFlagType;
begin
 getObjectWeight := getByte(DDBHeader.objWeightContWearPos + objno) and $3F;
end;

function getObjectFullWeight(objno:TLocationType):  TFlagType;
var w,w2,i: Word;
begin
    w := getObjectWeight(objno);
    if (isObjectContainer(objno) and (w<>0)) then 
        for i:= 0 to DDBHeader.numObj - 1 do
         if getObjectLocation(i) = objno then
          begin
           w2 := getObjectFullWeight(i);;
           if (w + w2 > high(TFlagType)) then w := high(TFlagType)
                                         else w:= w + w2;
          end; 
    getObjectFullWeight := w;
end; 



procedure resetObjects;
var  i: integer;
     carriedCount : word;
begin
    for i := 0 to NUM_OBJECTS-1 do setObjectLocation(i,LOC_NOT_CREATED);
    setFlag(FCARRIED,0);
    for i := 0 to DDBHeader.numObj - 1 do
    begin
     setObjectLocation(i,getByte(DDBHeader.objInitiallyAtPos + i));
     if getObjectLocation(i)=LOC_CARRIED then setFlag(FCARRIED, getFlag(FCARRIED)+1);
    end; 
end;

function getObjectLocation(objno: word):TLocationType;
begin
    getObjectLocation := objLocations[objno];
end;

procedure setObjectLocation(objno: word; value: TLocationType);
begin
    objLocations[objno] := value;
end;

procedure SetReferencedObject(objno: TFlagtype);
begin
    setFlag(FREFOBJ, objno);
    setFlag(FREFOBJLOC, getObjectLocation(objno));
    setFlag(FREFOBJWEIGHT, getByte(DDBHeader.objWeightContWearPos + objno) and $3F);
    if isObjectContainer(objno) then setFlag(FREFOBJCONTAINER, 128) 
                                else setFlag(FREFOBJCONTAINER, 0);
    if isObjectWearable(objno) then setFlag(FREFOBJWEARABLE, 128) 
                               else setFlag(FREFOBJWEARABLE, 0);
    setFlag(FREFOBJATTR2, getByte(DDBHeader.objAttributesPos + objno * 2));
    setFlag(FREFOBJATTR1, getByte(DDBHeader.objAttributesPos + objno * 2 + 1));
end;

function isObjectWearable(objno:TLocationType):boolean;
begin
    isObjectWearable := getByte(DDBHeader.objWeightContWearPos) AND $80 <> 0;
end;

function isObjectContainer(objno:TLocationType):boolean;
begin
    isObjectContainer := getByte(DDBHeader.objWeightContWearPos) AND $40 <> 0;
end;

function getObjectByVocabularyAtLocation(aNoun, anAdjective, location :TFlagType):TFlagType; 
var  i: integer;
     objectNoun : TFlagtype;
     objectAdject : TFlagtype;
begin
    for i := 0 to NUM_OBJECTS-1 do
     { if location = MAX_LOCATION, any location is valid} 
     if (location=MAX_LOCATION) or (getObjectLocation(i)=location) then
     begin
      objectNoun := getByte(DDBHeader.objNamePos + i * 2);
      objectAdject := getByte(DDBHeader.objNamePos + i * 2 + 1);
      if ((objectNoun = NO_WORD) OR (objectNoun = aNoun)) AND
         ((objectAdject = NO_WORD) OR (objectAdject = anAdjective)) 
         then 
         begin
          getObjectByVocabularyAtLocation := i;
          break;
         end;
     end;
     getObjectByVocabularyAtLocation := MAX_OBJECT;
end;

function getNextObjectAt(objno: integer; locno: TFlagType): TFlagType;
begin
 if locno = MAX_LOCATION then locno := getFlag(FPLAYER);
 repeat
 objno := objno + 1;
 until (objno = MAX_OBJECT) or  (getObjectLocation(objno) = locno);
 getNextObjectAt := objno;   
end;


end.