#!/bin/sh
set -e

wine ../../../../exec/asm68k.exe /k /m /o c+ /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- raise-error.asm, raise-error.gen, raise-error.sym, raise-error.lst
../../../../exec/convsym raise-error.sym raise-error.gen -a -ref 200
