@gcc -std=c++11 -Ofast -static -s -Wall ConvSym.cpp -o ConvSym.exe -lstdc++
@COPY /Y /B ConvSym.exe ..\..\modules\exec\ConvSym.exe
@pause
