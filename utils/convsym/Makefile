
BUILD_DIR ?= ../../build/utils
SRC_DIR ?= src
LIB_DIR ?= ../lib

EXEC_NAME = convsym
EXECUTABLE = $(BUILD_DIR)/$(EXEC_NAME)

CXXFLAGS ?= -std=c++23 -O2 -pedantic-errors -Wall -I$(LIB_DIR) $(shell pcre2-config --cflags)
LDFLAGS ?= -static -s $(shell pcre2-config --libs8)

.PHONY:	all convsym test clean

all:	convsym

convsym:	$(EXECUTABLE)

test:		$(EXECUTABLE)
	cd tests && ./test.py

clean:
	rm $(EXECUTABLE)

$(EXECUTABLE):	$(wildcard $(SRC_DIR)/*.cpp) $(wildcard $(SRC_DIR)/**/*.cpp) $(wildcard $(SRC_DIR)/**/*.hpp) $(wildcard $(LIB_DIR)/*.hpp)
$(EXECUTABLE):	| $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(SRC_DIR)/main.cpp $(LDFLAGS) -o $(EXECUTABLE)

$(BUILD_DIR):
	mkdir $(BUILD_DIR)
