@ECHO OFF
PATH D:\BIN;D:\LIB;D:\UNITS
ECHO Compiling PCDAAD unit tests (full rebuild)...
BPC -B -ED:\UNITS UNITTEST.PAS
IF ERRORLEVEL 1 GOTO ERROR
DEL *.TPU
ECHO.
ECHO Compilation OK. Run UNITTEST to execute the tests.
COPY D:\UNITS\UNITTEST.EXE
GOTO END
:ERROR
ECHO.
ECHO Compilation FAILED. Check errors above.
:END
