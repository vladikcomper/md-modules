SET PATH=..\..\..\exec;..\..\..\exec\as;..\..\..\..\utils\convsym;d:\sega\emulators\kega\

@echo off
cbundle test_flow
cls

echo --- Building ASM68K version ---
del test_flow-asm68k.gen
asm68k /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- test_flow-asm68k.asm, test_flow-asm68k.gen, test_flow-asm68k.sym, test_flow-asm68k.lst
ConvSym test_flow-asm68k.lst test_flow-asm68k.gen -input asm68k_lst -a
ConvSym test_flow-asm68k.sym test_flow-asm68k.gen -output deb1 -a -ref 200
del test_flow-asm68k.sym
if exist test_flow-asm68k.gen (
	test_flow-asm68k.gen fusion test_flow-asm68k.gen
	del test_flow-asm68k.lst
)

cls
echo --- Building AS version ---
del test_flow-as.gen
set AS_MSGPATH=..\..\..\exec\as
set USEANSI=n
asl -xx -A -L test_flow-as.asm
p2bin test_flow-as.p test_flow-as.gen -r 0x-0x
del test_flow-as.p
ConvSym test_flow-as.lst test_flow-as.gen -a -input as_lst
ConvSym test_flow-as.lst test_flow-as.gen -output deb1 -input as_lst -a -ref 200
if exist test_flow-as.gen (
	fusion test_flow-as.gen
	del test_flow-as.lst
)
