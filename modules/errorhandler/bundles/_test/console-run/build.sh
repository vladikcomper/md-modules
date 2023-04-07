#/usr/bin/sh
set -e

wine ../../../../exec/asm68k.exe /k /m /o c+ /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- console-run.asm, console-run.gen, , console-run.lst
../../../../exec/convsym console-run.lst console-run.gen -input asm68k_lst -a
../../../../exec/convsym console-run.lst console-run.gen -input asm68k_lst -output deb1 -a -ref 200
