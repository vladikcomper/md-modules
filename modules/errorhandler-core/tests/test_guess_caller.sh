#!/usr/bin/sh
set -e

cd ..

wine ../exec/asm68k.exe /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- _test/test_guess_caller.asm, _test/test_guess_caller.gen, _test/test_guess_caller.sym, _test/test_guess_caller.lst
../exec/convsym _test/test_guess_caller.sym _test/test_guess_caller.gen -a -ref 200
