
BUILD_DIR ?= ../../build/utils
SRC_DIR ?= src
LIB_DIR ?= ../lib

EXEC_NAME = convsym

# Windows builds use MinGW, so are statically linked for distribution convenience
ifeq ($(OS), Windows NT)
	LDFLAGS += -static
	EXEC_NAME = convsym.exe
endif

EXECUTABLE = $(BUILD_DIR)/$(EXEC_NAME)

CXXFLAGS ?= -std=c++20 -O3 -pedantic-errors -Wall -I../lib
LDFLAGS ?= -s

.PHONY:	all

all:	convsym

convsym:	$(EXECUTABLE)

test:		$(EXECUTABLE)
	cd tests && ./test.py

$(EXECUTABLE):	$(wildcard $(SRC_DIR)/*.cpp) $(wildcard $(SRC_DIR)/**/*.cpp) $(wildcard $(SRC_DIR)/**/*.hpp) $(wildcard $(LIB_DIR)/*.hpp)
$(EXECUTABLE):	| $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(SRC_DIR)/main.cpp -o $(EXECUTABLE)

$(BUILD_DIR):
	mkdir $(BUILD_DIR)
