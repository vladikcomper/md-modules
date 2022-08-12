@gcc -std=c++20 -O3 -pedantic-errors -s -Wall -static cbundle.cpp -o cbundle.exe -lstdc++
@COPY /Y /B cbundle.exe ..\..\modules\exec\cbundle.exe
@pause
