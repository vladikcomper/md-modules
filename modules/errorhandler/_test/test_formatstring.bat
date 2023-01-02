@echo off
..\..\exec\asm68k /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- test_formatstring.asm, test_formatstring.gen, test_formatstring.sym, test_formatstring.lst
..\..\exec\convsym.exe test_formatstring_dummy_symbols.log test_formatstring.gen -a -range 0 FFFFFF -input log -output deb2
..\..\exec\convsym.exe test_formatstring.sym test_formatstring.gen -output deb1 -a -ref 200
del test_formatstring.sym