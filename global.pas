{$I SETTINGS.INC}

(* Global constants, variables adn typedefs*)

unit GLOBAL;

interface

const VERSION='1.0 alpha 5';
      NO_WORD = $FF;
      END_OF_PROCESS_MARK = $00;
      END_OF_CONDACTS_MARK = $FF;
      END_OF_CONNECTIONS_MARK = $FF;
      NUM_LOCATIONS = 256;
      MAX_LOCATION = NUM_LOCATIONS -1;
      LAST_CONVERTIBLE_NOUN=19; {Nouns convertible to verb in absence of verb. i.e "NORTH"}
      LAST_PROPER_NOUN=50;

      FREQ_TABLE : array [0.. 9 * 12 -1] of Word = (
      16,17,18,19,21,22,23,24,26,28,29,31, {Octave 0: 24-46} 
      33,35,37,39,41,44,46,49,52,55,58,62, {Octave 1: 48-70}
      65,69,73,78,82,87,92,98,104,110,117,123, {Octave 2: 72-96}
      131,139,147,156,165,175,185,196,208,220,233,247, {Octave 3: 98-118}
      262,277,294,311,330,349,370,392,415,440,466,494, {Octave 4: 120-142}
      523,554,587,622,659,698,740,784,831,880,932,988, {Octave 5: 144-166}
      1047,1109,1175,1245,1319,1397,1480,1568,1661,1760,1865,1976, {Octave 6: 168-190}
      2093,2217,2349,2489,2637,2794,2960,3136,3322,3520,3729,3951, {Octave 7: 192-214}
      4186,4435,4699,4978,5274,5588,5920,6272,6645,7040,7459,7902 {Octave 8: 216-238} 
      );

      
{ The following constants are to be used so in case in the future some }
{ system message has to be changed, it's easier to replace everywhere. }

      SM0 = 0;
      SM1 = 1;
      SM2 = 2;
      SM3 = 3;
      SM4 = 4;
      SM5 = 5;
      SM6 = 6;
      SM7 = 7;
      SM8 = 8;
      SM9 = 9;
      SM10 = 10;
      SM11 = 11;
      SM12 = 12;
      SM13 = 13;
      SM14 = 14;
      SM15 = 15;
      SM16 = 16;
      SM17 = 17;
      SM18 = 18;
      SM19 = 19;
      SM20 = 20;
      SM21 = 21;
      SM22 = 22;
      SM23 = 23;
      SM24 = 24;
      SM25 = 25;
      SM26 = 26;
      SM27 = 27;
      SM28 = 28;
      SM29 = 29;
      SM30 = 30;
      SM31 = 31;
      SM32 = 32;
      SM33 = 33;
      SM34 = 34;
      SM35 = 35;
      SM36 = 36;
      SM37 = 37;
      SM38 = 38;
      SM39 = 39;
      SM40 = 40;
      SM41 = 41;
      SM42 = 42;
      SM43 = 43;
      SM44 = 44;
      SM45 = 45;
      SM46 = 46;
      SM47 = 47;
      SM48 = 48;
      SM49 = 49;
      SM50 = 50;
      SM51 = 51;
      SM52 = 52;
      SM53 = 53;
      SM54 = 54;
      SM55 = 55;
      SM56 = 56;
      SM57 = 57;
      SM58 = 58;
      SM59 = 59;
      SM60 = 60;
      SM61 = 61;
      SM62 = 62;
      SM63 = 63;
      SM64 = 64;
      SM65 = 65;
      SM66 = 66;
      SM67 = 67;
      SM68 = 68;
      SM69 = 69;
      SM70 = 70;
      
type DWORD=longint;
type TFlagType = byte;

procedure CopyRight;

implementation

procedure CopyRight;
begin
  Writeln('PC DAAD Interpreter ',version,' (C) Uto 2021');
end;

end.