#!/usr/bin/sh
set -e

cd ..

wine ../exec/asm68k.exe /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- _test/test_fullexception.asm, _test/test_fullexception.gen, _test/test_fullexception.sym, _test/test_fullexception.lst
../exec/convsym _test/test_fullexception.sym _test/test_fullexception.gen -a
