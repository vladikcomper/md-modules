#!/bin/sh
set -e

cbundle=../cbundle

if [ ! -z "$USE_VALGRIND" ]; then
	cbundle="valgrind ../cbundle"
fi

cd _test

$cbundle test.asm

diff -qs output-1.txt output-1.txt.model
diff -qs output-2.txt output-2.txt.model

