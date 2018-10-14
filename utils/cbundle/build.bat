@g++ -std=c++11 -Ofast -static -s -Wall cbundle.cpp -o cbundle.exe
@COPY /Y /B cbundle.exe ..\..\modules\exec\cbundle.exe
@pause
