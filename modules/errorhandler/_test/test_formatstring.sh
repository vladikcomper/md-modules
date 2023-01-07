set -e
wine ../../exec/asm68k.exe /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- test_formatstring.asm, test_formatstring.gen, test_formatstring.sym, test_formatstring.lst
../../exec/convsym test_formatstring_dummy_symbols.log test_formatstring.gen -a -range 0 FFFFFF -input log -output deb2 -ref 200
rm test_formatstring.sym
