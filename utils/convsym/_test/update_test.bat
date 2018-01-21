@echo off
..\convsym sonic1.sym sonic1.deb2.model -input asm68k_sym
..\convsym sonic2.lst sonic2.deb2.model -input as_lst
..\convsym sonic2.lst sonic2.log.model -input as_lst -output log
..\convsym sonic3k.lst sonic3k.deb2.model -input as_lst

..\convsym sonic1.sym sonic1.deb1.model -input asm68k_sym -output deb1
..\convsym sonic2.lst sonic2.deb1.model -input as_lst -output deb1
..\convsym sonic3k.lst sonic3k.deb1.model -input as_lst -output deb1

..\convsym sonic1.sym sonic1.log -input asm68k_sym -output log
..\convsym sonic1.sym sonic1.asm -input asm68k_sym -output asm

..\convsym s1built.lst s1built.log.model -input asm68k_lst -output log -debug>s1built.log.txt
..\convsym test.lst test.log.model -input asm68k_lst -output log

pause