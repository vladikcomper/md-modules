#!/bin/sh
set -e

wine ../../../../exec/asm68k.exe /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- raise-error.asm, raise-error.gen, raise-error.sym, raise-error.lst
../../../../exec/convsym raise-error.lst raise-error.gen -input asm68k_lst -a
../../../../exec/convsym raise-error.sym raise-error.gen -output deb1 -a -ref 200
rm raise-error.sym
