@echo off
SET PATH=..\..\..\exec;..\..\..\exec\as;..\..\..\..\utils\convsym

if exist test_dummy-asm68k.gen del test_dummy-asm68k.gen
asm68k /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- test_dummy-asm68k.asm, test_dummy-asm68k.gen, test_dummy-asm68k.sym, test_dummy-asm68k.lst
ConvSym test_dummy-asm68k.lst test_dummy-asm68k.gen -input asm68k_lst -a
ConvSym test_dummy-asm68k.sym test_dummy-asm68k.gen -output deb1 -a -ref 200
del test_dummy-asm68k.sym