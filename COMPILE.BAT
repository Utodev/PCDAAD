PATH D:\BIN;D:\LIB;D:\UNITS
BPC -B -    
del *.tpu
BPC -B -ED:\UNITS PCDAAD.PAS
del *.tpu
copy D:\UNITS\PCDAAD.EXE
