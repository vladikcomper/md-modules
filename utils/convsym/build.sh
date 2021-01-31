#!/bin/sh
set -e

gcc -std=c++11 -Ofast -s -Wall ConvSym.cpp -o convsym -lstdc++
cp convsym ../../modules/exec/convsym
