
BUILD_DIR ?= ../../build
SRC_DIR ?= src
LIB_DIR ?= ../lib

EXEC_NAME = convsym

# Windows builds use MinGW, so are statically linked for distribution convenience
ifeq ($(OS), Windows NT)
	LDFLAGS += -static
	EXEC_NAME = convsym.exe
endif

EXEC_PATH = $(BUILD_DIR)/$(EXEC_NAME)

CXXFLAGS ?= -std=c++20 -O3 -pedantic-errors -Wall -I../lib
LDFLAGS ?= -s

.PHONY:	all

all:	convsym

convsym:	$(EXEC_PATH)

test:		$(EXEC_PATH)
	cd tests && ./test.py

$(EXEC_PATH):	$(wildcard $(SRC_DIR)/*.cpp) $(wildcard $(SRC_DIR)/**/*.cpp) $(wildcard $(SRC_DIR)/**/*.hpp) $(wildcard $(LIB_DIR)/*.hpp)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(SRC_DIR)/main.cpp -o $(EXEC_PATH)
