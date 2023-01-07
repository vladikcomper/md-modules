#!/usr/bin/sh
set -e

wine ../../../../exec/asm68k.exe /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- hello-world.asm, hello-world.gen, hello-world.sym, hello-world.lst
../../../../exec/convsym hello-world.sym hello-world.gen -a -ref 200 -debug
