#!/bin/sh
set -e

echo --- Generating bundles ---
../../../../exec/cbundle flow-test.asm -def ASM68K -out flow-test-asm68k.out.asm
../../../../exec/cbundle flow-test.asm -def ASM -out flow-test-as.out.asm

echo --- Building ASM68K version ---
wine ../../../../exec/asm68k.exe /k /m /o c+ /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- flow-test-asm68k.out.asm, flow-test-asm68k.gen, flow-test-asm68k.sym, flow-test-asm68k.lst
../../../../exec/convsym flow-test-asm68k.sym flow-test-asm68k.gen -a -ref 200

echo --- Building AS version ---
set AS_MSGPATH=..\..\..\exec\as
set USEANSI=n
wine ../../../../exec/as/asl.exe -xx -A -L flow-test-as.out.asm
wine ../../../../exec/as/p2bin.exe flow-test-as.p flow-test-as.gen -r 0x-0x
rm flow-test-as.p
../../../../exec/convsym flow-test-as.lst flow-test-as.gen -input as_lst -a -ref 200
