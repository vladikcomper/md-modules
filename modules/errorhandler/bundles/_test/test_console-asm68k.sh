#/usr/bin/sh
set -e

wine ../../../exec/asm68k.exe /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- test_console-asm68k.asm, test_console-asm68k.gen, , test_console-asm68k.lst
../../../exec/convsym test_console-asm68k.lst test_console-asm68k.gen -input asm68k_lst -a
../../../exec/convsym test_console-asm68k.lst test_console-asm68k.gen -input asm68k_lst -output deb1 -a -ref 200
