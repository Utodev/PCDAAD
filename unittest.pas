{$I SETTINGS.INC}
{$R-}

{ PCDAAD Unit Tests  -  Borland Pascal 7 / DOSBox

  Compile : RUNTEST.BAT
  Run     : UNITTEST.EXE

  Condacts that print text (GET, DROP, WEAR, REMOVE...) call WriteText,
  which writes to VGA memory at $A000. Without startVideoMode the screen
  is in text mode, so those writes are harmless - the assertions only
  check flag / object state, not what is displayed.
}

program RunTests;

uses global, strings, flags, ddb, objects, condacts;

{ ======================================================================
  FRAMEWORK
  ====================================================================== }

var
  PassCount, FailCount, SectionFails: integer;

procedure Check(condition: boolean; testName: String);
begin
  if condition then
  begin
    Inc(PassCount);
    WriteLn('  PASS: ', testName);
  end
  else
  begin
    Inc(FailCount);
    Inc(SectionFails);
    WriteLn('  FAIL: ', testName);
  end;
end;

procedure Section(title: String);
begin
  SectionFails := 0;
  WriteLn;
  WriteLn('[', title, ']');
end;

procedure SectionEnd;
begin
  if SectionFails = 0 then WriteLn('  (all passed)')
                      else WriteLn('  (', SectionFails, ' failure(s))');
end;

{ ======================================================================
  TEST DDB

  Minimal DDB with 4 test objects:
    Obj0 - at location 2,       noun=10, adj=255, weight=1
    Obj1 - LOC_CARRIED (254),   noun=20, adj=255, weight=2
    Obj2 - LOC_WORN    (253),   noun=30, adj=5,   weight=2, container+wearable
    Obj3 - LOC_NOT_CREATED(252),noun=40, adj=255, weight=5

  Header layout (34 bytes) followed by object tables:
    Offset 34  : initial locations (4 bytes)
    Offset 38  : noun+adj pairs    (8 bytes)
    Offset 46  : weight/cont/wear  (4 bytes)
    Offset 50  : attributes        (8 bytes)
    Offset 58  : sysmess pointer table (102 bytes, message# 0..50)
    Offset 160 : shared sysmess text ("OK" + terminator, 3 bytes)

  Sysmess table: any condact that prints a system message (GET, DROP,
  WEAR, REMOVE...) calls Sysmess(), which indexes this table by message
  number. Without real entries, getPcharMessageInternal reads a garbage
  pointer past the end of the buffer and walks off into unrelated memory
  looking for a terminator - it doesn't crash cleanly, it just hangs.
  All messages actually exercised by the tests point at the same 3-byte
  placeholder text; the tests only assert on flag/object state, never on
  the printed text, and the placeholder deliberately contains no '_'
  (object-name escape) since objectPos isn't populated either.
  ====================================================================== }

const
  TEST_NUM_OBJ = 4;
  TEST_NUM_LOC = 5;
  SYSMESS_TABLE_POS = 58;   { word-per-message pointer table, msg# 0..50 }
  SYSMESS_TEXT_POS  = 160;  { shared placeholder text all entries point to }

var
  TestDDB: array[0..162] of byte;

procedure SetSysmessEntry(msgNum: word);
begin
  TestDDB[SYSMESS_TABLE_POS + 2*msgNum]     := lo(SYSMESS_TEXT_POS);
  TestDDB[SYSMESS_TABLE_POS + 2*msgNum + 1] := hi(SYSMESS_TEXT_POS);
end;

procedure InitTestDDB;
begin
  FillChar(TestDDB, SizeOf(TestDDB), 0);

  { Single-byte header fields (offsets 0-7) }
  TestDDB[ 0] := 2;             { version = V2 }
  TestDDB[ 1] := 0;             { English }
  TestDDB[ 3] := TEST_NUM_OBJ;  { numObj  }
  TestDDB[ 4] := TEST_NUM_LOC;  { numLoc  }
  TestDDB[ 7] := 1;             { numPro  }

  { Word fields: objInitiallyAtPos=34, objNamePos=38,
    objWeightContWearPos=46, objAttributesPos=50, fileLength=58 }
  TestDDB[24] := 34;
  TestDDB[26] := 38;
  TestDDB[28] := 46;
  TestDDB[30] := 50;
  TestDDB[32] := 58;

  { Initial locations (offset 34) }
  TestDDB[34] := 2;
  TestDDB[35] := LOC_CARRIED;
  TestDDB[36] := LOC_WORN;
  TestDDB[37] := LOC_NOT_CREATED;

  { Noun + adj (offset 38) }
  TestDDB[38] := 10;  TestDDB[39] := NO_WORD;
  TestDDB[40] := 20;  TestDDB[41] := NO_WORD;
  TestDDB[42] := 30;  TestDDB[43] := 5;
  TestDDB[44] := 40;  TestDDB[45] := NO_WORD;

  { Weight / container / wearable (offset 46) }
  TestDDB[46] := 1;     { Obj0: weight=1 }
  TestDDB[47] := 2;     { Obj1: weight=2 }
  TestDDB[48] := $C2;   { Obj2: wearable($80)+container($40)+weight=2 }
  TestDDB[49] := 5;     { Obj3: weight=5 }

  { Attributes (offset 50) - all zero by FillChar }

  { Shared placeholder sysmess text: 'O','K' obfuscated (byte XOR $FF),
    terminated by ($0A xor $FF), matching getPcharMessageInternal's encoding }
  TestDDB[SYSMESS_TEXT_POS]     := byte(Ord('O')) xor OFUSCATE_VALUE;
  TestDDB[SYSMESS_TEXT_POS + 1] := byte(Ord('K')) xor OFUSCATE_VALUE;
  TestDDB[SYSMESS_TEXT_POS + 2] := $0A xor OFUSCATE_VALUE;

  DDBRAM := @TestDDB;

  { Sysmess pointer table entries for every message number the tested
    condacts (_GET, _REMOVE) can actually print }
  SetSysmessEntry(SM23); { I'm not wearing one of those }
  SetSysmessEntry(SM27); { I can't carry any more things }
  SetSysmessEntry(SM36); { I now have the _ }
  SetSysmessEntry(SM38); { I've removed the _ }
  SetSysmessEntry(SM41); { I can't remove the _ }
  SetSysmessEntry(SM42); { I can't remove the _. My hands are full }
  SetSysmessEntry(SM50); { I'm not wearing the _ }

  DDBHeader.version              := 2;
  DDBHeader.targetMachineLanguage := 0;
  DDBHeader.the95                := 0;
  DDBHeader.numObj               := TEST_NUM_OBJ;
  DDBHeader.numLoc               := TEST_NUM_LOC;
  DDBHeader.numMsg               := 0;
  DDBHeader.numSys               := 51;
  DDBHeader.numPro               := 1;
  DDBHeader.tokenPos             := 0;
  DDBHeader.processPos           := 0;
  DDBHeader.objectPos            := 0;
  DDBHeader.locationPos          := 0;
  DDBHeader.messagePos           := 0;
  DDBHeader.sysmessPos           := SYSMESS_TABLE_POS;
  DDBHeader.connectionPos        := 0;
  DDBHeader.vocabularyPos        := 0;
  DDBHeader.objInitiallyAtPos    := 34;
  DDBHeader.objNamePos           := 38;
  DDBHeader.objWeightContWearPos := 46;
  DDBHeader.objAttributesPos     := 50;
  DDBHeader.fileLength           := SizeOf(TestDDB);

  { Safe initial process pointers }
  EntryPTR   := 0;
  CondactPTR := 0;
  ProcessPTR := 0;
  DoallPTR   := 0;
end;

procedure ResetState;
begin
  resetFlags;
  resetObjects;
  setFlag(FPLAYER,             3);
  setFlag(FOBJECTS_CONVEYABLE, 5);
  setFlag(FPLAYER_STRENGTH,   50);
  Done          := false;
  condactResult := true;
  EntryPTR      := 0;
  CondactPTR    := 0;
end;

{ ======================================================================
  FLAG TESTS
  ====================================================================== }

procedure RunFlagTests;
var i: integer;
    ok: boolean;
begin
  Section('FLAGS - get/set');
  resetFlags;

  setFlag(0, 42);
  Check(getFlag(0) = 42, 'setFlag/getFlag (flag 0 = 42)');

  setFlag(255, 255);
  Check(getFlag(255) = 255, 'setFlag/getFlag boundary (flag 255 = 255)');

  setFlag(128, 0);
  Check(getFlag(128) = 0, 'setFlag to 0');

  setFlag(FVERB, 77);
  Check(getFlag(33) = 77, 'setFlag uses named constant FVERB=33');

  ok := true;
  for i := 0 to 255 do
  begin
    setFlag(i, i);
    if getFlag(i) <> i then ok := false;
  end;
  Check(ok, 'all 256 flags round-trip correctly');
  SectionEnd;

  Section('FLAGS - bit operations');
  resetFlags;

  setFlag(10, 0);
  setFlagBit(10, 0);
  Check(getFlag(10) = 1, 'setFlagBit bit 0');

  setFlag(10, 0);
  setFlagBit(10, 7);
  Check(getFlag(10) = 128, 'setFlagBit bit 7');

  setFlag(10, $FF);
  clearFlagBit(10, 0);
  Check(getFlag(10) = $FE, 'clearFlagBit bit 0');

  setFlag(10, $FF);
  clearFlagBit(10, 7);
  Check(getFlag(10) = $7F, 'clearFlagBit bit 7');

  setFlag(10, 0);
  toggleFlagBit(10, 3);
  Check(getFlag(10) = 8, 'toggleFlagBit sets bit 3');
  toggleFlagBit(10, 3);
  Check(getFlag(10) = 0, 'toggleFlagBit clears bit 3');

  setFlag(10, $55);
  Check(getFlagBit(10, 0) = true,  'getFlagBit: bit 0 of $55 is set');
  Check(getFlagBit(10, 1) = false, 'getFlagBit: bit 1 of $55 is clear');
  Check(getFlagBit(10, 6) = true,  'getFlagBit: bit 6 of $55 is set');
  Check(getFlagBit(10, 7) = false, 'getFlagBit: bit 7 of $55 is clear');
  SectionEnd;

  Section('FLAGS - resetFlags');
  setFlag(5, 100);  setFlag(200, 200);
  resetFlags;
  ok := true;
  for i := 0 to 255 do if getFlag(i) <> 0 then ok := false;
  Check(ok, 'resetFlags zeroes all 256 flags');
  SectionEnd;

  Section('FLAGS - RAM save/load');
  resetFlags;
  setFlag(0, 10);  setFlag(1, 20);  setFlag(50, 99);
  RAMSaveFlags;
  setFlag(0, 0);   setFlag(1, 0);   setFlag(50, 0);
  RAMLoadFlags(255);
  Check(getFlag(0)  = 10, 'RAMLoadFlags 255: flag 0 restored');
  Check(getFlag(1)  = 20, 'RAMLoadFlags 255: flag 1 restored');
  Check(getFlag(50) = 99, 'RAMLoadFlags 255: flag 50 restored');

  { Partial restore }
  setFlag(0, 99);  setFlag(1, 99);  setFlag(2, 99);
  RAMSaveFlags;
  setFlag(0, 0);   setFlag(1, 0);   setFlag(2, 0);
  RAMLoadFlags(1);
  Check(getFlag(0) = 99, 'RAMLoadFlags 1: flag 0 restored');
  Check(getFlag(1) = 99, 'RAMLoadFlags 1: flag 1 restored');
  Check(getFlag(2) = 0,  'RAMLoadFlags 1: flag 2 NOT restored');
  SectionEnd;
end;

{ ======================================================================
  OBJECT TESTS
  ====================================================================== }

procedure RunObjectTests;
var i: integer;
    ok: boolean;
begin
  Section('OBJECTS - location get/set');
  setObjectLocation(0, 2);
  setObjectLocation(1, LOC_CARRIED);
  setObjectLocation(2, LOC_WORN);
  setObjectLocation(3, LOC_NOT_CREATED);
  Check(getObjectLocation(0) = 2,               'Obj0 at loc 2');
  Check(getObjectLocation(1) = LOC_CARRIED,     'Obj1 carried');
  Check(getObjectLocation(2) = LOC_WORN,        'Obj2 worn');
  Check(getObjectLocation(3) = LOC_NOT_CREATED, 'Obj3 not created');
  SectionEnd;

  Section('OBJECTS - resetObjects');
  ResetState;
  Check(getObjectLocation(0) = 2,               'resetObjects: Obj0 at initial loc 2');
  Check(getObjectLocation(1) = LOC_CARRIED,     'resetObjects: Obj1 initially carried');
  Check(getObjectLocation(2) = LOC_WORN,        'resetObjects: Obj2 initially worn');
  Check(getObjectLocation(3) = LOC_NOT_CREATED, 'resetObjects: Obj3 initially not created');
  Check(getFlag(FCARRIED) = 1, 'resetObjects: FCARRIED=1 (only Obj1 counts, not worn Obj2)');
  SectionEnd;

  Section('OBJECTS - getObjectCountAt');
  ResetState;
  setObjectLocation(0, 5);  setObjectLocation(1, 5);
  setObjectLocation(2, 5);  setObjectLocation(3, 7);
  Check(getObjectCountAt(5) = 3, '3 objects at loc 5');
  Check(getObjectCountAt(7) = 1, '1 object at loc 7');
  Check(getObjectCountAt(0) = 0, '0 objects at loc 0');
  SectionEnd;

  Section('OBJECTS - getNextObjectAt');
  ResetState;
  setObjectLocation(0, 5);  setObjectLocation(1, 7);
  setObjectLocation(2, 5);  setObjectLocation(3, 5);
  Check(getNextObjectAt(-1, 5) = 0,          'first object at loc 5 is Obj0');
  Check(getNextObjectAt(0,  5) = 2,          'next after Obj0 at loc 5 is Obj2');
  Check(getNextObjectAt(2,  5) = 3,          'next after Obj2 at loc 5 is Obj3');
  Check(getNextObjectAt(3,  5) = MAX_OBJECT, 'no more at loc 5 after Obj3');
  Check(getNextObjectAt(-1, 9) = MAX_OBJECT, 'nothing at empty loc 9');
  SectionEnd;

  Section('OBJECTS - weight/container/wearable');
  ResetState;
  Check(getObjectWeight(0) = 1,     'Obj0 weight=1');
  Check(getObjectWeight(1) = 2,     'Obj1 weight=2');
  Check(getObjectWeight(2) = 2,     'Obj2 weight=2 (low 6 bits of $C2)');
  Check(getObjectWeight(3) = 5,     'Obj3 weight=5');
  Check(isObjectWearable(2)  = true,  'Obj2 is wearable');
  Check(isObjectWearable(0)  = false, 'Obj0 is not wearable');
  Check(isObjectContainer(2) = true,  'Obj2 is container');
  Check(isObjectContainer(1) = false, 'Obj1 is not container');
  SectionEnd;

  Section('OBJECTS - getObjectFullWeight (containers)');
  ResetState;
  { Put Obj0 (w=1) and Obj1 (w=2) inside container Obj2 (w=2) }
  setObjectLocation(0, 2);
  setObjectLocation(1, 2);
  Check(getObjectFullWeight(2) = 5, 'container Obj2: own(2)+Obj0(1)+Obj1(2)=5');
  Check(getObjectFullWeight(0) = 1, 'non-container Obj0=1');
  Check(getObjectFullWeight(3) = 5, 'non-container Obj3=5');
  SectionEnd;

  Section('OBJECTS - getObjectByVocabularyAtLocation');
  ResetState;
  setObjectLocation(0, 3);  setObjectLocation(1, 3);
  setObjectLocation(2, 3);  setObjectLocation(3, 7);
  Check(getObjectByVocabularyAtLocation(10, NO_WORD, 3) = 0,
        'noun=10 at loc 3 -> Obj0');
  Check(getObjectByVocabularyAtLocation(20, NO_WORD, 3) = 1,
        'noun=20 at loc 3 -> Obj1');
  Check(getObjectByVocabularyAtLocation(30, 5, 3) = 2,
        'noun=30 adj=5 at loc 3 -> Obj2');
  Check(getObjectByVocabularyAtLocation(40, NO_WORD, 3) = MAX_OBJECT,
        'noun=40 NOT at loc 3 -> not found');
  Check(getObjectByVocabularyAtLocation(40, NO_WORD, 7) = 3,
        'noun=40 at loc 7 -> Obj3');
  Check(getObjectByVocabularyAtLocation(99, NO_WORD, 3) = MAX_OBJECT,
        'unknown noun -> not found');
  { Partial match: typed noun only, object has adjective }
  Check(getObjectByVocabularyAtLocation(30, NO_WORD, 3) = 2,
        'partial match noun=30 adj=any -> Obj2');
  { Any-location search }
  Check(getObjectByVocabularyAtLocation(40, NO_WORD, MAX_LOCATION) = 3,
        'MAX_LOCATION finds Obj3 regardless of location');
  SectionEnd;

  Section('OBJECTS - RAM save/load');
  ResetState;
  setObjectLocation(0, 10);  setObjectLocation(1, 11);
  RAMSaveObjects;
  setObjectLocation(0, 20);  setObjectLocation(1, 20);
  RAMLoadObjects;
  Check(getObjectLocation(0) = 10, 'RAMLoadObjects: Obj0 restored to 10');
  Check(getObjectLocation(1) = 11, 'RAMLoadObjects: Obj1 restored to 11');
  SectionEnd;
end;

{ ======================================================================
  CONDITION CONDACT TESTS
  ====================================================================== }

procedure RunConditionTests;
begin
  Section('CONDACTS - AT / NOTAT / ATGT / ATLT');
  ResetState;
  setFlag(FPLAYER, 5);

  Parameter1 := 5;  _AT;   Check(condactResult = true,  '_AT:   player=5  param=5 -> true');
  Parameter1 := 3;  _AT;   Check(condactResult = false, '_AT:   player=5  param=3 -> false');
  Parameter1 := 3;  _NOTAT; Check(condactResult = true,  '_NOTAT: player=5  param=3 -> true');
  Parameter1 := 5;  _NOTAT; Check(condactResult = false, '_NOTAT: player=5  param=5 -> false');
  Parameter1 := 4;  _ATGT; Check(condactResult = true,  '_ATGT: 5>4 -> true');
  Parameter1 := 5;  _ATGT; Check(condactResult = false, '_ATGT: 5>5 -> false');
  Parameter1 := 6;  _ATLT; Check(condactResult = true,  '_ATLT: 5<6 -> true');
  Parameter1 := 5;  _ATLT; Check(condactResult = false, '_ATLT: 5<5 -> false');
  SectionEnd;

  Section('CONDACTS - ZERO / NOTZERO / EQ / GT / LT / NOTEQ / SAME / NOTSAME / BIGGER / SMALLER');
  ResetState;
  setFlag(10, 0);
  Parameter1 := 10;  _ZERO;   Check(condactResult = true,  '_ZERO:    flag=0 -> true');
  setFlag(10, 1);
  _ZERO;             Check(condactResult = false, '_ZERO:    flag=1 -> false');

  setFlag(10, 5);
  Parameter1 := 10;  _NOTZERO; Check(condactResult = true,  '_NOTZERO: flag=5 -> true');
  setFlag(10, 0);
  _NOTZERO;          Check(condactResult = false, '_NOTZERO: flag=0 -> false');

  setFlag(10, 42);
  Parameter1 := 10;  Parameter2 := 42; _EQ; Check(condactResult = true,  '_EQ:   42=42 -> true');
  Parameter2 := 41;                    _EQ; Check(condactResult = false, '_EQ:   42=41 -> false');

  Parameter1 := 10;  Parameter2 := 41; _GT; Check(condactResult = true,  '_GT:   42>41 -> true');
  Parameter2 := 42;                    _GT; Check(condactResult = false, '_GT:   42>42 -> false');

  Parameter1 := 10;  Parameter2 := 43; _LT; Check(condactResult = true,  '_LT:   42<43 -> true');
  Parameter2 := 42;                    _LT; Check(condactResult = false, '_LT:   42<42 -> false');

  Parameter1 := 10;  Parameter2 := 99; _NOTEQ; Check(condactResult = true,  '_NOTEQ: 42<>99 -> true');
  Parameter2 := 42;                    _NOTEQ; Check(condactResult = false, '_NOTEQ: 42<>42 -> false');

  setFlag(10, 7);  setFlag(11, 7);
  Parameter1 := 10;  Parameter2 := 11; _SAME;    Check(condactResult = true,  '_SAME:    7=7 -> true');
  setFlag(11, 8);
  _SAME;                                          Check(condactResult = false, '_SAME:    7<>8 -> false');

  setFlag(11, 8);
  Parameter1 := 10;  Parameter2 := 11; _NOTSAME; Check(condactResult = true,  '_NOTSAME: 7<>8 -> true');
  setFlag(11, 7);
  _NOTSAME;                                       Check(condactResult = false, '_NOTSAME: 7=7 -> false');

  setFlag(10, 10); setFlag(11, 5);
  Parameter1 := 10;  Parameter2 := 11; _BIGGER;  Check(condactResult = true,  '_BIGGER:  10>5 -> true');
  setFlag(10, 5);
  _BIGGER;                                        Check(condactResult = false, '_BIGGER:  5=5 -> false');

  setFlag(10, 3);  setFlag(11, 9);
  Parameter1 := 10;  Parameter2 := 11; _SMALLER; Check(condactResult = true,  '_SMALLER: 3<9 -> true');
  setFlag(10, 9);
  _SMALLER;                                       Check(condactResult = false, '_SMALLER: 9=9 -> false');
  SectionEnd;

  Section('CONDACTS - PRESENT / ABSENT / WORN / NOTWORN / CARRIED / NOTCARR');
  ResetState;
  setFlag(FPLAYER, 3);
  setObjectLocation(0, 3);          { at player location }
  setObjectLocation(1, LOC_CARRIED);
  setObjectLocation(2, LOC_WORN);
  setObjectLocation(3, LOC_NOT_CREATED);

  Parameter1 := 0; _PRESENT; Check(condactResult = true,  '_PRESENT: at loc -> true');
  Parameter1 := 1; _PRESENT; Check(condactResult = true,  '_PRESENT: carried -> true');
  Parameter1 := 2; _PRESENT; Check(condactResult = true,  '_PRESENT: worn -> true');
  Parameter1 := 3; _PRESENT; Check(condactResult = false, '_PRESENT: not created -> false');

  Parameter1 := 3; _ABSENT; Check(condactResult = true,  '_ABSENT: not created -> true');
  Parameter1 := 0; _ABSENT; Check(condactResult = false, '_ABSENT: at loc -> false');

  Parameter1 := 2; _WORN;    Check(condactResult = true,  '_WORN: Obj2 worn -> true');
  Parameter1 := 1; _WORN;    Check(condactResult = false, '_WORN: Obj1 carried not worn -> false');
  Parameter1 := 1; _NOTWORN; Check(condactResult = true,  '_NOTWORN: carried not worn -> true');
  Parameter1 := 2; _NOTWORN; Check(condactResult = false, '_NOTWORN: worn -> false');

  Parameter1 := 1; _CARRIED;  Check(condactResult = true,  '_CARRIED: Obj1 carried -> true');
  Parameter1 := 2; _CARRIED;  Check(condactResult = false, '_CARRIED: worn not carried -> false');
  Parameter1 := 2; _NOTCARR;  Check(condactResult = true,  '_NOTCARR: worn -> true');
  Parameter1 := 1; _NOTCARR;  Check(condactResult = false, '_NOTCARR: carried -> false');
  SectionEnd;

  Section('CONDACTS - ISAT / ISNOTAT');
  ResetState;
  setFlag(FPLAYER, 3);
  setObjectLocation(0, 7);

  Parameter1 := 0; Parameter2 := 7; _ISAT;
  Check(condactResult = true,  '_ISAT: Obj0 at 7, param2=7 -> true');
  Parameter1 := 0; Parameter2 := 5; _ISAT;
  Check(condactResult = false, '_ISAT: Obj0 at 7, param2=5 -> false');
  { LOC_HERE substitution }
  setObjectLocation(0, 3);
  Parameter1 := 0; Parameter2 := LOC_HERE; _ISAT;
  Check(condactResult = true, '_ISAT: LOC_HERE resolves to FPLAYER=3, Obj0 at 3 -> true');

  setObjectLocation(0, 7);
  Parameter1 := 0; Parameter2 := 7; _ISNOTAT;
  Check(condactResult = false, '_ISNOTAT: Obj0 at 7, param2=7 -> false');
  Parameter1 := 0; Parameter2 := 5; _ISNOTAT;
  Check(condactResult = true,  '_ISNOTAT: Obj0 at 7, param2=5 -> true');
  SectionEnd;

  Section('CONDACTS - CHANCE');
  Parameter1 := 100; _CHANCE; Check(condactResult = true,  '_CHANCE 100 always succeeds');
  Parameter1 := 101; _CHANCE; Check(condactResult = false, '_CHANCE 101 (>100) always fails');
  SectionEnd;

  Section('CONDACTS - ISDONE / ISNDONE');
  Done := true;
  _ISDONE;  Check(condactResult = true,  '_ISDONE:  Done=true  -> true');
  _ISNDONE; Check(condactResult = false, '_ISNDONE: Done=true  -> false');
  Done := false;
  _ISDONE;  Check(condactResult = false, '_ISDONE:  Done=false -> false');
  _ISNDONE; Check(condactResult = true,  '_ISNDONE: Done=false -> true');
  SectionEnd;
end;

{ ======================================================================
  ACTION CONDACT TESTS
  ====================================================================== }

procedure RunActionTests;
begin
  Section('CONDACTS - SET / CLEAR / LET / PLUS / MINUS');
  ResetState;

  Parameter1 := 20; _SET;
  Check(getFlag(20) = 255, '_SET: flag 20 = MAX (255)');
  Check(done = true,       '_SET: sets done');

  Parameter1 := 20; _CLEAR;
  Check(getFlag(20) = 0, '_CLEAR: flag 20 = 0');

  Parameter1 := 20; Parameter2 := 77; _LET;
  Check(getFlag(20) = 77, '_LET: flag 20 = 77');

  setFlag(20, 10); Parameter1 := 20; Parameter2 := 5;  _PLUS;
  Check(getFlag(20) = 15, '_PLUS: 10+5=15');
  setFlag(20, 250); Parameter2 := 10; _PLUS;
  Check(getFlag(20) = 255, '_PLUS: overflow clamps to 255');

  setFlag(20, 20); Parameter1 := 20; Parameter2 := 8;  _MINUS;
  Check(getFlag(20) = 12, '_MINUS: 20-8=12');
  setFlag(20, 5);  Parameter2 := 10; _MINUS;
  Check(getFlag(20) = 0, '_MINUS: underflow clamps to 0');
  SectionEnd;

  Section('CONDACTS - ADD / SUB');
  ResetState;
  setFlag(10, 30); setFlag(11, 20);
  Parameter1 := 10; Parameter2 := 11; _ADD;
  Check(getFlag(11) = 50, '_ADD: flag11(20) += flag10(30) = 50');
  setFlag(10, 200); setFlag(11, 200);
  Parameter1 := 10; Parameter2 := 11; _ADD;
  Check(getFlag(11) = 255, '_ADD: overflow clamps to 255');

  setFlag(10, 5); setFlag(11, 20);
  Parameter1 := 10; Parameter2 := 11; _SUB;
  Check(getFlag(11) = 15, '_SUB: flag11(20) -= flag10(5) = 15');
  setFlag(10, 30); setFlag(11, 10);
  Parameter1 := 10; Parameter2 := 11; _SUB;
  Check(getFlag(11) = 0, '_SUB: underflow clamps to 0');
  SectionEnd;

  Section('CONDACTS - GOTO');
  ResetState;
  setFlag(FPLAYER, 3);
  Parameter1 := 7; _GOTO;
  Check(getFlag(FPLAYER) = 7, '_GOTO: player moved to 7');
  Check(done = true,           '_GOTO: sets done');
  SectionEnd;

  Section('CONDACTS - PLACE / CREATE / DESTROY / SWAP');
  ResetState;
  setFlag(FCARRIED, 1);
  setObjectLocation(0, 5);
  setObjectLocation(1, LOC_CARRIED);

  { PLACE non-carried to another location }
  Parameter1 := 0; Parameter2 := 9; _PLACE;
  Check(getObjectLocation(0) = 9, '_PLACE: Obj0 moved to loc 9');
  Check(getFlag(FCARRIED) = 1,    '_PLACE: FCARRIED unchanged (Obj0 not carried)');

  { PLACE from CARRIED -> FCARRIED decrements }
  Parameter1 := 1; Parameter2 := 5; _PLACE;
  Check(getObjectLocation(1) = 5, '_PLACE from CARRIED: Obj1 at loc 5');
  Check(getFlag(FCARRIED) = 0,    '_PLACE from CARRIED: FCARRIED decremented');

  { PLACE to CARRIED -> FCARRIED increments }
  Parameter1 := 0; Parameter2 := LOC_CARRIED; _PLACE;
  Check(getObjectLocation(0) = LOC_CARRIED, '_PLACE to CARRIED: Obj0 now carried');
  Check(getFlag(FCARRIED) = 1,              '_PLACE to CARRIED: FCARRIED incremented');

  { PLACE with LOC_HERE }
  setFlag(FPLAYER, 4);
  Parameter1 := 1; Parameter2 := LOC_HERE; _PLACE;
  Check(getObjectLocation(1) = 4, '_PLACE LOC_HERE resolves to FPLAYER=4');

  { CREATE }
  ResetState;
  setFlag(FPLAYER, 6);
  setObjectLocation(3, LOC_NOT_CREATED);
  Parameter1 := 3; _CREATE;
  Check(getObjectLocation(3) = 6, '_CREATE: Obj3 placed at player loc 6');

  { DESTROY }
  Parameter1 := 3; _DESTROY;
  Check(getObjectLocation(3) = LOC_NOT_CREATED, '_DESTROY: Obj3 moved to LOC_NOT_CREATED');

  { SWAP }
  setObjectLocation(0, 10); setObjectLocation(1, 20);
  Parameter1 := 0; Parameter2 := 1; _SWAP;
  Check(getObjectLocation(0) = 20, '_SWAP: Obj0 now at 20');
  Check(getObjectLocation(1) = 10, '_SWAP: Obj1 now at 10');
  SectionEnd;

  Section('CONDACTS - COPYOF / COPYFF / COPYBF / COPYOO / COPYFO');
  ResetState;
  setObjectLocation(0, 7);

  Parameter1 := 0; Parameter2 := 15; _COPYOF;
  Check(getFlag(15) = 7, '_COPYOF: flag 15 = Obj0 location (7)');

  setFlag(10, 42);
  Parameter1 := 10; Parameter2 := 20; _COPYFF;
  Check(getFlag(20) = 42, '_COPYFF: flag 20 = flag 10 (42)');

  setFlag(10, 0); setFlag(11, 99);
  Parameter1 := 10; Parameter2 := 11; _COPYBF;
  Check(getFlag(10) = 99, '_COPYBF: flag 10 = flag 11 (99)');

  setObjectLocation(0, 5); setObjectLocation(1, 3);
  Parameter1 := 0; Parameter2 := 1; _COPYOO;
  Check(getObjectLocation(1) = 5, '_COPYOO: Obj1 placed at Obj0 location (5)');

  setFlag(10, 8);
  Parameter1 := 10; Parameter2 := 2; _COPYFO;
  Check(getObjectLocation(2) = 8, '_COPYFO: Obj2 placed at location in flag 10 (8)');
  SectionEnd;

  Section('CONDACTS - RANDOM / WEIGH / WEIGHT');
  ResetState;
  Parameter1 := 20; _RANDOM;
  Check((getFlag(20) >= 1) and (getFlag(20) <= 100), '_RANDOM: result in 1..100');

  setObjectLocation(0, 5);
  Parameter1 := 0; Parameter2 := 15; _WEIGH;
  Check(getFlag(15) = 1, '_WEIGH: flag 15 = Obj0 weight (1)');
  Parameter1 := 3; Parameter2 := 15; _WEIGH;
  Check(getFlag(15) = 5, '_WEIGH: flag 15 = Obj3 weight (5)');

  setObjectLocation(0, LOC_CARRIED);
  setObjectLocation(1, LOC_WORN);
  setObjectLocation(2, LOC_NOT_CREATED);
  setObjectLocation(3, LOC_NOT_CREATED);
  Parameter1 := 20; _WEIGHT;
  Check(getFlag(20) = 3, '_WEIGHT: carried Obj0(1) + worn Obj1(2) = 3');
  SectionEnd;
end;

{ ======================================================================
  BUG REGRESSION TESTS
  ====================================================================== }

procedure RunBugTests;
begin
  Section('REGRESSION - BUG#1: _REMOVE used FPLAYER instead of FCARRIED');
  { Old code: if getFlag(FPLAYER) >= getFlag(FOBJECTS_CONVEYABLE)
    This compared room number (flag38) to max-carry (flag37), so
    REMOVE blocked based on which room you were in, not how full
    your hands were.  Fix: use FCARRIED (flag1). }

  { Case 1: hands empty (FCARRIED=0), player at room 10, max=5.
    Old: 10 >= 5 = true  -> wrongly blocked.
    New: 0  >= 5 = false -> correctly allowed. }
  ResetState;
  setFlag(FPLAYER,             10);
  setFlag(FOBJECTS_CONVEYABLE,  5);
  setFlag(FCARRIED,             0);
  setObjectLocation(2, LOC_WORN);   { Obj2 is wearable }
  Parameter1 := 2;  Done := false;
  _REMOVE;
  Check(getObjectLocation(2) = LOC_CARRIED,
        'BUG#1 fixed: REMOVE with FCARRIED=0 moves worn item to carried');
  Check(getFlag(FCARRIED) = 1,
        'BUG#1 fixed: FCARRIED incremented after successful REMOVE');

  { Case 2: hands truly full (FCARRIED=5 >= FOBJECTS_CONVEYABLE=5).
    REMOVE must still be blocked. }
  ResetState;
  setFlag(FPLAYER,             1);
  setFlag(FOBJECTS_CONVEYABLE, 2);
  setFlag(FCARRIED,            2);
  setObjectLocation(2, LOC_WORN);
  Parameter1 := 2;  Done := false;
  _REMOVE;
  Check(getObjectLocation(2) = LOC_WORN,
        'BUG#1 verify: REMOVE blocked when FCARRIED >= FOBJECTS_CONVEYABLE');
  SectionEnd;

  Section('REGRESSION - GET capacity check (reference - was always correct)');
  ResetState;
  setFlag(FPLAYER, 3);
  setFlag(FCARRIED, 0);
  setFlag(FOBJECTS_CONVEYABLE, 5);
  setFlag(FPLAYER_STRENGTH, 50);
  setObjectLocation(0, 3);
  Parameter1 := 0;  Done := false;
  _GET;
  Check(getObjectLocation(0) = LOC_CARRIED, '_GET: Obj0 picked up');
  Check(getFlag(FCARRIED) = 1,              '_GET: FCARRIED incremented');

  ResetState;
  setFlag(FPLAYER, 3);
  setFlag(FCARRIED, 5);
  setFlag(FOBJECTS_CONVEYABLE, 5);
  setObjectLocation(0, 3);
  Parameter1 := 0;  Done := false;
  _GET;
  Check(getObjectLocation(0) = 3, '_GET: blocked when FCARRIED >= FOBJECTS_CONVEYABLE');
  SectionEnd;

  Section('REGRESSION - PLACE FCARRIED accounting');
  ResetState;
  setFlag(FCARRIED, 1);
  setObjectLocation(0, LOC_CARRIED);
  Parameter1 := 0; Parameter2 := 5; _PLACE;
  Check(getFlag(FCARRIED) = 0,
        '_PLACE from CARRIED decrements FCARRIED (1->0)');

  setFlag(FCARRIED, 0);
  setObjectLocation(0, 7);
  Parameter1 := 0; Parameter2 := LOC_CARRIED; _PLACE;
  Check(getFlag(FCARRIED) = 1,
        '_PLACE to CARRIED increments FCARRIED (0->1)');
  SectionEnd;
end;

{ ======================================================================
  MAIN
  ====================================================================== }

begin
  WriteLn('PCDAAD Unit Tests  (Borland Pascal 7 / DOSBox)');
  WriteLn('===============================================');
  PassCount := 0;
  FailCount := 0;

  InitTestDDB;
  ResetState;

  RunFlagTests;
  RunObjectTests;
  RunConditionTests;
  RunActionTests;
  RunBugTests;

  WriteLn;
  WriteLn('===============================================');
  WriteLn('Results: ', PassCount, ' passed, ', FailCount, ' failed.');
  if FailCount = 0 then WriteLn('ALL TESTS PASSED.')
                   else WriteLn('SOME TESTS FAILED.');
  WriteLn;
end.
