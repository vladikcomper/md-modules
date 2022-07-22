#!/bin/sh
set -e

cd _test
convsym=../convsym

echo "-- Testing DEB2 symbol generation... --"
$convsym sonic1.sym sonic1.deb2 -input asm68k_sym
zcat sonic2.lst.gz  | $convsym - sonic2.deb2 -input as_lst
zcat sonic3k.lst.gz | $convsym - sonic3k.deb2 -input as_lst

echo "-- Testing DEB1 symbol generation... --"
echo "WARNING: Sonic 3K tests will throw a few errors, because symbol list is too large for DEB1 format to handle."
echo "Errors are suppressed by default."
$convsym sonic1.sym sonic1.deb1 -input asm68k_sym -output deb1
zcat sonic2.lst.gz  | $convsym - sonic2.deb1 -input as_lst -output deb1
zcat sonic3k.lst.gz | $convsym - sonic3k.deb1 -input as_lst -output deb1 2> /dev/null

echo "-- Testing LOG symbol generation... --"
zcat s1built.lst.gz | $convsym - s1built.log -input asm68k_lst -output log -inopt "/localSign=@ /localJoin=. /ignoreMacroExp+ /ignoreMacroDefs+ /addMacrosAsOpcodes+ /processLocals+"
$convsym test.lst test.log -input asm68k_lst -output log
$convsym logtest.in.log logtest.out.log -input log -output log -inopt "/separator=: /useDecimal+"

echo "-- Testing asm68k_sym parser on Sonic 1 Hivebrain diassembly... --"
$convsym sonic1.sym sonic1.sym.log -input asm68k_sym -output log
$convsym sonic1.sym sonic1.sym.asm -input asm68k_sym -output asm

echo "-- Testing asm68k_sym and asm68k_lst parsers on Sonic 1 Git diassembly... --"
zcat sonic1git.lst.gz | $convsym - sonic1git.lst.log -in asm68k_lst -out log -tolower -inopt "/localSign=@ /localJoin=. /ignoreMacroExp- /ignoreMacroDefs- /addMacrosAsOpcodes+ /processLocals+"
$convsym sonic1git.sym sonic1git.sym.log -in asm68k_sym -out log -tolower -inopt "/localSign=@ /localJoin=. /processLocals+"

echo "-- Comparing results to the correct data --"
echo "NOTICE: If you see differring files below, this indicates TEST FAILURE:"

diff -q sonic1.deb1 sonic1.deb1.model
diff -q sonic2.deb1 sonic2.deb1.model
diff -q sonic3k.deb1 sonic3k.deb1.model

diff -q sonic1.deb2 sonic1.deb2.model
diff -q sonic2.deb2 sonic2.deb2.model
diff -q sonic3k.deb2 sonic3k.deb2.model

diff -q s1built.log s1built.log.model
diff -q test.log test.log.model
diff -q logtest.out.log logtest.out.log.model

diff -q sonic1.sym.log sonic1.sym.log.model
diff -q sonic1.sym.asm sonic1.sym.asm.model

diff -q sonic1git.lst.log sonic1git.lst.log.model
diff -q sonic1git.sym.log sonic1git.sym.log.model

echo "ALL DONE!"