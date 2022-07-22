@gcc -std=c++20 -O3 -pedantic-errors -static -s -Wall ConvSym.cpp -o ConvSym.exe -lstdc++
@COPY /Y /B ConvSym.exe ..\..\modules\exec\ConvSym.exe
@pause
