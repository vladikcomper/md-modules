#!/bin/bash
gcc -std=c++11 -Ofast -s -Wall cbundle.cpp -o cbundle -lstdc++
cp cbundle ../../modules/exec/cbundle

