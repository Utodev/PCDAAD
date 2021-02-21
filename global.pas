{$I SETTINGS.INC}

(* Global constants, variables adn typedefs*)

unit GLOBAL;

interface

const VERSION='1.0';
      NO_WORD = $FF;
      END_OF_PROCESS_MARK = $00;
      END_OF_CONDACTS_MARK = $FF;
      NUM_LOCATIONS = 256;
      MAX_LOCATION = NUM_LOCATIONS -1;

{ The following constants are to be used so in case in the future some }
{ system message has to be changed, it's easier to replace everywhere. }

      SYSMESS0 = 0;
      SYSMESS1 = 1;
      SYSMESS2 = 2;
      SYSMESS3 = 3;
      SYSMESS4 = 4;
      SYSMESS5 = 5;
      SYSMESS6 = 6;
      SYSMESS7 = 7;
      SYSMESS8 = 8;
      SYSMESS9 = 9;
      SYSMESS10 = 10;
      SYSMESS11 = 11;
      SYSMESS12 = 12;
      SYSMESS13 = 13;
      SYSMESS14 = 14;
      SYSMESS15 = 15;
      SYSMESS16 = 16;
      SYSMESS17 = 17;
      SYSMESS18 = 18;
      SYSMESS19 = 19;
      SYSMESS20 = 20;
      SYSMESS21 = 21;
      SYSMESS22 = 22;
      SYSMESS23 = 23;
      SYSMESS24 = 24;
      SYSMESS25 = 25;
      SYSMESS26 = 26;
      SYSMESS27 = 27;
      SYSMESS28 = 28;
      SYSMESS29 = 29;
      SYSMESS30 = 30;
      SYSMESS31 = 31;
      SYSMESS32 = 32;
      SYSMESS33 = 33;
      SYSMESS34 = 34;
      SYSMESS35 = 35;
      SYSMESS36 = 36;
      SYSMESS37 = 37;
      SYSMESS38 = 38;
      SYSMESS39 = 39;
      SYSMESS40 = 40;
      SYSMESS41 = 41;
      SYSMESS42 = 42;
      SYSMESS43 = 43;
      SYSMESS44 = 44;
      SYSMESS45 = 45;
      SYSMESS46 = 46;
      SYSMESS47 = 47;
      SYSMESS48 = 48;
      SYSMESS49 = 49;
      SYSMESS50 = 50;
      SYSMESS51 = 51;
      SYSMESS52 = 52;
      SYSMESS53 = 53;
      SYSMESS54 = 54;
      SYSMESS55 = 55;
      SYSMESS56 = 56;
      SYSMESS57 = 57;
      SYSMESS58 = 58;
      SYSMESS59 = 59;
      SYSMESS60 = 60;
      SYSMESS61 = 61;
      SYSMESS62 = 62;
      SYSMESS63 = 63;
      SYSMESS64 = 64;
      SYSMESS65 = 65;
      SYSMESS66 = 66;
      SYSMESS67 = 67;
      SYSMESS68 = 68;
      SYSMESS69 = 69;
      SYSMESS70 = 70;
      
type DWORD=longint;
type TFlagType = byte;

implementation

end.