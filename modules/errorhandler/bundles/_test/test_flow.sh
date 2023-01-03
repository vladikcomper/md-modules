#!/bin/sh
set -e

../../../exec/cbundle test_flow.cbundle

echo --- Building ASM68K version ---
wine ../../../exec/asm68k.exe /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- test_flow-asm68k.asm, test_flow-asm68k.gen, test_flow-asm68k.sym, test_flow-asm68k.lst
../../../exec/convsym test_flow-asm68k.lst test_flow-asm68k.gen -input asm68k_lst -a
../../../exec/convsym test_flow-asm68k.sym test_flow-asm68k.gen -output deb1 -a -ref 200
rm test_flow-asm68k.sym

echo --- Building AS version ---
set AS_MSGPATH=..\..\..\exec\as
set USEANSI=n
wine ../../../exec/as/asl.exe -xx -A -L test_flow-as.asm
wine ../../../exec/as/p2bin.exe test_flow-as.p test_flow-as.gen -r 0x-0x
rm test_flow-as.p
../../../exec/convsym test_flow-as.lst test_flow-as.gen -a -input as_lst
../../../exec/convsym test_flow-as.lst test_flow-as.gen -output deb1 -input as_lst -a -ref 200
