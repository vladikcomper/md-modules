
BUILD_DIR ?= ../../build
SRC_DIR ?= src
LIB_DIR ?= ../lib

EXEC_NAME = cbundle

# Windows builds use MinGW, so are statically linked for distribution convenience
ifeq ($(OS), Windows NT)
	LDFLAGS += -static
	EXEC_NAME = cbundle.exe
endif

EXEC_PATH = $(BUILD_DIR)/$(EXEC_NAME)

CXXFLAGS ?= -std=c++20 -O3 -pedantic-errors -Wall -I../lib
LDFLAGS ?= -s

.PHONY:	all

all:	cbundle readme

cbundle:	$(EXEC_PATH)

test:		$(EXEC_PATH)
	cd tests && ./test.py

# Executable returns non-zero exit code when the help is displayed, so we have to ignore it
readme:		$(EXEC_PATH)
	$(EXEC_PATH) > readme.txt || true

$(EXEC_PATH):	$(wildcard $(SRC_DIR)/*.cpp) $(wildcard $(LIB_DIR)/*.hpp)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(SRC_DIR)/main.cpp -o $(EXEC_PATH)
