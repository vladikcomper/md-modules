@gcc -std=c++11 -Ofast -s -Wall cbundle.cpp -o cbundle.exe -lstdc++
@COPY /Y /B cbundle.exe ..\..\modules\exec\cbundle.exe
@pause
