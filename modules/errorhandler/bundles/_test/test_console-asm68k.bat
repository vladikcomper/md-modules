@echo off
SET PATH=..\..\..\exec;..\..\..\exec\as;..\..\..\..\utils\convsym;d:\sega\emulators\kega\

if exist test_console-asm68k.gen del test_console-asm68k.gen
asm68k /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- test_console-asm68k.asm, test_console-asm68k.gen, test_console-asm68k.sym, test_console-asm68k.lst
ConvSym test_console-asm68k.lst test_console-asm68k.gen -input asm68k_lst -a
ConvSym test_console-asm68k.sym test_console-asm68k.gen -output deb1 -a -ref 200
del test_console-asm68k.sym
if exist test_console-asm68k.gen (
	fusion test_console-asm68k.gen
	del test_console-asm68k.lst
)