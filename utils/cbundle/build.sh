#!/bin/bash
set -e

cc -std=c++20 -O3 -pedantic-errors -s -Wall cbundle.cpp -o cbundle -lstdc++
cp cbundle ../../modules/exec/cbundle
