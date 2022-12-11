#!/bin/sh
set -e

cc -std=c++20 -O3 -pedantic-errors -s -Wall convsym.cpp -o convsym -lstdc++
cp convsym ../../modules/exec/convsym
