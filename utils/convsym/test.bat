@echo off
cd .\_test

..\convsym sonic1.sym sonic1.deb2 -input asm68k_sym
..\convsym sonic2.lst sonic2.deb2 -input as_lst
..\convsym sonic3k.lst sonic3k.deb2 -input as_lst -debug >sonic3k.txt

..\convsym sonic1.sym sonic1.deb1 -input asm68k_sym -output deb1
..\convsym sonic2.lst sonic2.deb1 -input as_lst -output deb1
..\convsym sonic3k.lst sonic3k.deb1 -input as_lst -output deb1

copy s2built.bin.model s2built.bin
..\convsym sonic2.lst s2built.bin -a -input as_lst

..\convsym s1built.lst s1built.log -input asm68k_lst -output log -inopt "/localSign=@ /localJoin=. /ignoreMacroExp+ /ignoreMacroDefs+ /addMacrosAsOpcodes+ /processLocals+"
..\convsym test.lst test.log -input asm68k_lst -output log

cls

FC /B sonic1.deb1 sonic1.deb1.model
FC /B sonic2.deb1 sonic2.deb1.model
FC /B sonic3k.deb1 sonic3k.deb1.model

FC /B sonic1.deb2 sonic1.deb2.model
FC /B sonic2.deb2 sonic2.deb2.model
FC /B sonic3k.deb2 sonic3k.deb2.model

FC s1built.log s1built.log.model
FC test.log test.log.model

pause
