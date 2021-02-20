{$I SETTINGS.INC}

unit objects;


interface

uses global;

type TLocationType = byte;

const MAX_OBJECTS = 256;
      LOC_NOT_CREATED = 252;
      LOC_CARRIED = 254;
      LOC_WORN = 253;
      

function getObjectLocation(objno: word):TLocationType;
function getObjectWeight(objno: word): TFlagType;
function isObjectWearable(objno:TLocationType):boolean;
function isObjectContainer(objno:TLocationType):boolean;
function getObjectFullWeight(objno:TLocationType): TFlagType; {Gets weight of object in depth if container}
procedure setObjectLocation(objno: word; value: TLocationType);
procedure SetReferencedObject(objno: TFlagtype); {Sets the currently referenced object}
procedure resetObjects; {Places the objects at their initial locations}
procedure RAMSaveObjects; {Makes a copy of object locations in RAM}
procedure RAMLoadObjects; {Restore a copy of object locations in RAM}
function WhatObject(locno: TLocationType):Word; {Tries to find a object referenced by current name and adject at this location}


implementation

uses flags, ddb;

var objLocations: array [0..MAX_OBJECTS-1] of byte;
    objLocationsRAMSAVE: array [0..MAX_OBJECTS-1] of byte;
    
procedure RAMSaveObjects;
begin   
 move(objLocations, objLocationsRAMSAVE, sizeof(objLocations));
end; 

procedure RAMLoadObjects;
begin   
 move(objLocationsRAMSAVE, objLocations, sizeof(objLocations));
end; 

function WhatObject(locno: TLocationType):Word;  
var i: word;
begin
 WhatObject:= $FFFF; {Returns $FFFF if not found}
 for i := 0 to DDBHeader.numObj - 1 do
 begin
 end;

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
    for i := 0 to MAX_OBJECTS-1 do setObjectLocation(i,LOC_NOT_CREATED);
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
    {Unlike what would be expected, flag for lower attributes is the upper one, and viceversa}
    setFlag(FREFOBJATTR1, getByte(DDBHeader.objAttributesPos + objno * 2 + 1));
    setFlag(FREFOBJATTR2, getByte(DDBHeader.objAttributesPos + objno * 2));
end;

function isObjectWearable(objno:TLocationType):boolean;
begin
    isObjectWearable := getByte(DDBHeader.objWeightContWearPos) AND $80 <> 0;
end;

function isObjectContainer(objno:TLocationType):boolean;
begin
    isObjectContainer := getByte(DDBHeader.objWeightContWearPos) AND $40 <> 0;
end;


end.