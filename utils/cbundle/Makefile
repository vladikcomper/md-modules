
BUILD_DIR ?= ../../build/utils
SRC_DIR ?= src
LIB_DIR ?= ../lib

EXEC_NAME = cbundle
EXECUTABLE = $(BUILD_DIR)/$(EXEC_NAME)

CXXFLAGS ?= -std=c++20 -O2 -pedantic-errors -Wall -I../lib
LDFLAGS ?= -s

.PHONY:	all cbundle test clean

all:	cbundle readme.txt

cbundle:	$(EXECUTABLE)

test:		$(EXECUTABLE)
	cd tests && ./test.py

clean:
	rm -f $(EXECUTABLE)

# Executable returns non-zero exit code when the help is displayed, so we have to ignore it
readme.txt:	$(EXECUTABLE)
	$(EXECUTABLE) > readme.txt || true

$(EXECUTABLE):	$(wildcard $(SRC_DIR)/*.cpp) $(wildcard $(LIB_DIR)/*.hpp)
$(EXECUTABLE):	| $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(SRC_DIR)/main.cpp -o $(EXECUTABLE)

$(BUILD_DIR):
	mkdir $(BUILD_DIR)
