
BUILD_DIR ?= ../../build/modules/mdshell-core
SRC_DIR ?= .
CORE_DIR ?= ../core

ASM68K ?= wine ../exec/asm68k.exe
ASFLAGS = /k /m /o c+ /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae-

.PHONY:	all release debug clean

all:	release debug

release:	$(BUILD_DIR)/MDShell.bin $(BUILD_DIR)/MDShell.sym

debug:	$(BUILD_DIR)/MDShell.Debug.bin $(BUILD_DIR)/MDShell.Debug.sym

clean:
	rm -f $(BUILD_DIR)/*.*

$(BUILD_DIR)/MDShell.bin $(BUILD_DIR)/MDShell.sym &:	$(wildcard $(SRC_DIR)/*.asm) $(wildcard $(CORE_DIR)/*.asm) | $(BUILD_DIR)
	$(ASM68K) $(ASFLAGS) $(SRC_DIR)/MDShell.asm, $(BUILD_DIR)/MDShell.bin, $(BUILD_DIR)/MDShell.sym, $(BUILD_DIR)/MDShell.lst

$(BUILD_DIR)/MDShell.Debug.bin $(BUILD_DIR)/MDShell.Debug.sym &:	$(wildcard $(SRC_DIR)/*.asm) $(wildcard $(CORE_DIR)/*.asm) | $(BUILD_DIR)
	$(ASM68K) $(ASFLAGS) /e __DEBUG__ $(SRC_DIR)/MDShell.asm, $(BUILD_DIR)/MDShell.Debug.bin, $(BUILD_DIR)/MDShell.Debug.sym, $(BUILD_DIR)/MDShell.Debug.lst

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
