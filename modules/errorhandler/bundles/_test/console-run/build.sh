#/usr/bin/sh
set -e

wine ../../../../exec/asm68k.exe /k /m /o c+ /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- console-run.asm, console-run.gen, console-run.sym, console-run.lst
../../../../exec/convsym console-run.sym console-run.gen -input asm68k_sym -output deb2 -a -ref 200
