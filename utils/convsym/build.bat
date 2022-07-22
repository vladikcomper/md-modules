@gcc -std=c++20 -O3 -pedantic-errors -static -s -Wall convsym.cpp -o convsym.exe -lstdc++
@COPY /Y /B convsym.exe ..\..\modules\exec\convsym.exe
@pause
