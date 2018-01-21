@echo off
cd _test
..\cbundle test.asm
fc output-1.txt output-1.txt.model
fc output-2.txt output-2.txt.model
pause
