
BUILD_DIR ?= ../../build/modules/errorhandler-core
SRC_DIR ?= .
CORE_DIR ?= ../core

ASM68K ?= wine ../exec/asm68k.exe
ASFLAGS = /k /m /o c+ /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae-

.PHONY:	all release	debug extsym clean

all:	release	debug extsym

release:	$(BUILD_DIR)/ErrorHandler.bin $(BUILD_DIR)/ErrorHandler.sym

debug:	$(BUILD_DIR)/ErrorHandler.Debug.bin $(BUILD_DIR)/ErrorHandler.Debug.sym

extsym:	$(BUILD_DIR)/ErrorHandler.ExtSymbols.bin $(BUILD_DIR)/ErrorHandler.ExtSymbols.sym

clean:
	rm -f $(BUILD_DIR)/*.*

$(BUILD_DIR)/ErrorHandler.bin $(BUILD_DIR)/ErrorHandler.sym &:	$(SRC_DIR)/ErrorHandler.asm $(wildcard $(CORE_DIR)/*.asm) | $(BUILD_DIR)
	$(ASM68K) $(ASFLAGS) $(SRC_DIR)/ErrorHandler.asm, $(BUILD_DIR)/ErrorHandler.bin, $(BUILD_DIR)/ErrorHandler.sym, $(BUILD_DIR)/ErrorHandler.lst

$(BUILD_DIR)/ErrorHandler.Debug.bin $(BUILD_DIR)/ErrorHandler.Debug.sym &:	$(SRC_DIR)/ErrorHandler.asm $(wildcard $(CORE_DIR)/*.asm) | $(BUILD_DIR)
	$(ASM68K) $(ASFLAGS) /e __DEBUG__ $(SRC_DIR)/ErrorHandler.asm, $(BUILD_DIR)/ErrorHandler.Debug.bin, $(BUILD_DIR)/ErrorHandler.Debug.sym, $(BUILD_DIR)/ErrorHandler.Debug.lst

$(BUILD_DIR)/ErrorHandler.ExtSymbols.bin $(BUILD_DIR)/ErrorHandler.ExtSymbols.sym &:	$(SRC_DIR)/ErrorHandler.asm $(wildcard $(CORE_DIR)/*.asm) | $(BUILD_DIR)
	$(ASM68K) $(ASFLAGS) /e _USE_SYMBOL_DATA_REF_=1 /e SymbolData_Ptr=0 $(SRC_DIR)/ErrorHandler.asm, $(BUILD_DIR)/ErrorHandler.ExtSymbols.bin, $(BUILD_DIR)/ErrorHandler.ExtSymbols.sym, $(BUILD_DIR)/ErrorHandler.ExtSymbols.lst

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
