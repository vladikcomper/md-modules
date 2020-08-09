#!/bin/sh
cd _test
convsym=../convsym

echo "-- Testing DEB2 symbol generation... --"
$convsym sonic1.sym sonic1.deb2 -debug -input asm68k_sym
$convsym sonic2.lst sonic2.deb2 -input as_lst
$convsym sonic3k.lst sonic3k.deb2 -input as_lst -debug >sonic3k.txt

echo "-- Testing DEB1 symbol generation... --"
echo "WARNING: Sonic 3K tests will throw a few errors, because symbol list is too large for DEB1 format to handle."
echo "Please ignore any errors, unless the final stage of testing shows that the resulting files differ (see below)."
$convsym sonic1.sym sonic1.deb1 -input asm68k_sym -output deb1
$convsym sonic2.lst sonic2.deb1 -input as_lst -output deb1
$convsym sonic3k.lst sonic3k.deb1 -input as_lst -output deb1

echo "-- Testing LOG symbol generation... --"
$convsym s1built.lst s1built.log -input asm68k_lst -output log -inopt "/localSign=@ /localJoin=. /ignoreMacroExp+ /ignoreMacroDefs+ /addMacrosAsOpcodes+ /processLocals+"
$convsym test.lst test.log -input asm68k_lst -output log
$convsym logtest.in.log logtest.out.log -input log -output log -inopt "/separator=: /useDecimal+"

echo "-- Comparing results to the correct data --"
echo "NOTICE: If any of the files below differ, this indicates a test failure!"

diff -qs sonic1.deb1 sonic1.deb1.model
diff -qs sonic2.deb1 sonic2.deb1.model
diff -qs sonic3k.deb1 sonic3k.deb1.model

diff -qs sonic1.deb2 sonic1.deb2.model
diff -qs sonic2.deb2 sonic2.deb2.model
diff -qs sonic3k.deb2 sonic3k.deb2.model

diff -qs s1built.log s1built.log.model
diff -qs test.log test.log.model
diff -qs logtest.out.log logtest.out.log.model
