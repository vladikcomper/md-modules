#!/bin/sh
set -e

wine ../../../exec/asm68k.exe /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- test_dummy-asm68k.asm, test_dummy-asm68k.gen, test_dummy-asm68k.sym, test_dummy-asm68k.lst
../../../exec/convsym test_dummy-asm68k.lst test_dummy-asm68k.gen -input asm68k_lst -a
../../../exec/convsym test_dummy-asm68k.sym test_dummy-asm68k.gen -output deb1 -a -ref 200
rm test_dummy-asm68k.sym
