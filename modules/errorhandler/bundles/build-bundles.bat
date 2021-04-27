@echo off

copy /Y /B ..\errorhandler.debug.bin _test\ErrorHandler.bin

echo --- BUILDING BUNDLE-ASM68K ---
md bundle-asm68k
..\..\exec\cbundle bundle-asm68k.asm
copy /Y /B ..\errorhandler.bin bundle-asm68k\ErrorHandler.bin

echo --- BUILDING BUNDLE-ASM68K-DEBUG ---
md bundle-asm68k-debug
..\..\exec\cbundle bundle-asm68k-debug.asm
copy /Y /B ..\errorhandler.debug.bin bundle-asm68k-debug\ErrorHandler.bin


echo --- BUILDING BUNDLE-AS ---
md bundle-as
..\..\exec\cbundle bundle-as.asm
copy /Y /B ..\errorhandler.bin bundle-as\ErrorHandler.bin
