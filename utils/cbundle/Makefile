
BUILD_DIR ?= ../../build/utils
SRC_DIR ?= src
LIB_DIR ?= ../lib

EXEC_NAME = cbundle

# Windows builds use MinGW, so are statically linked for distribution convenience
ifeq ($(OS), Windows NT)
	LDFLAGS += -static
	EXEC_NAME = cbundle.exe
endif

EXECUTABLE = $(BUILD_DIR)/$(EXEC_NAME)

CXXFLAGS ?= -std=c++20 -O3 -pedantic-errors -Wall -I../lib
LDFLAGS ?= -s

.PHONY:	all

all:	cbundle readme

cbundle:	$(EXECUTABLE)

test:		$(EXECUTABLE)
	cd tests && ./test.py

# Executable returns non-zero exit code when the help is displayed, so we have to ignore it
readme:		$(EXECUTABLE)
	$(EXECUTABLE) > readme.txt || true

$(EXECUTABLE):	$(wildcard $(SRC_DIR)/*.cpp) $(wildcard $(LIB_DIR)/*.hpp)
$(EXECUTABLE):	| $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(SRC_DIR)/main.cpp -o $(EXECUTABLE)

$(BUILD_DIR):
	mkdir $(BUILD_DIR)
