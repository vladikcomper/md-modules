
BUILD_DIR ?= ../../build/utils
SRC_DIR ?= src
LIB_DIR ?= ../lib

EXEC_NAME = convsym
EXECUTABLE = $(BUILD_DIR)/$(EXEC_NAME)

CXXFLAGS ?= -std=c++20 -O2 -pedantic-errors -Wall -I$(LIB_DIR)
LDFLAGS ?= -s

.PHONY:	all convsym test clean

all:	convsym

convsym:	$(EXECUTABLE)

test:		$(EXECUTABLE)
	cd tests && ./test.py

clean:
	rm $(EXECUTABLE)

$(EXECUTABLE):	$(wildcard $(SRC_DIR)/*.cpp) $(wildcard $(SRC_DIR)/**/*.cpp) $(wildcard $(SRC_DIR)/**/*.hpp) $(wildcard $(LIB_DIR)/*.hpp)
$(EXECUTABLE):	| $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(SRC_DIR)/main.cpp -o $(EXECUTABLE)

$(BUILD_DIR):
	mkdir $(BUILD_DIR)
