
include ../../utils/.Makefile # For $(CONVSYM), $(CBUNDLE) etc


BUILD_DIR ?= ../../build/modules/mdshell-core
SRC_DIR ?= .

SRC_FILES ?= $(wildcard $(SRC_DIR)/*.asm) $(wildcard ../errorhandler-core/*.asm) $(wildcard ../core/*.asm)

ASM68K ?= wine ../exec/asm68k.exe
ASFLAGS = /k /m /o c+ /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae-

.PHONY:	all release Headless clean

all:	release headless

release:	$(BUILD_DIR)/MDShell.Blob.asm $(BUILD_DIR)/MDShell.Globals.asm

headless:	$(BUILD_DIR)/MDShell.Headless.Blob.asm

clean:
	rm -f $(BUILD_DIR)/*.*


# Raw unlinked binaries

$(BUILD_DIR)/MDShell.bin $(BUILD_DIR)/MDShell.sym &:	$(SRC_FILES) | $(BUILD_DIR)
	$(ASM68K) $(ASFLAGS) $(SRC_DIR)/MDShell.asm, $(BUILD_DIR)/MDShell.bin, $(BUILD_DIR)/MDShell.sym, $(BUILD_DIR)/MDShell.lst

$(BUILD_DIR)/MDShell.Headless.bin $(BUILD_DIR)/MDShell.Headless.sym &:	$(SRC_FILES) | $(BUILD_DIR)
	$(ASM68K) $(ASFLAGS) /e _HEADLESS_=1 $(SRC_DIR)/MDShell.asm, $(BUILD_DIR)/MDShell.Headless.bin, $(BUILD_DIR)/MDShell.Headless.sym, $(BUILD_DIR)/MDShell.Headless.lst


# Global symbol tables

$(BUILD_DIR)/MDShell.Globals.asm:	$(BUILD_DIR)/MDShell.sym | $(BUILD_DIR) $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -filter "__global_.+"


# Linkable blobs in assembly format

$(BUILD_DIR)/MDShell.Blob.asm:	$(BUILD_DIR)/MDShell.bin $(BUILD_DIR)/MDShell.SymbolTable.log $(SRC_DIR)/inject-tables/MDShell.txt | $(BUILD_DIR)
	$(BLOBTOASM) $(BUILD_DIR)/MDShell.bin $@ -t $(BUILD_DIR)/MDShell.SymbolTable.log -m $(SRC_DIR)/inject-tables/MDShell.txt

$(BUILD_DIR)/MDShell.Headless.Blob.asm:	$(BUILD_DIR)/MDShell.Headless.bin $(BUILD_DIR)/MDShell.Headless.SymbolTable.log $(SRC_DIR)/inject-tables/MDShell.txt | $(BUILD_DIR)
	$(BLOBTOASM) $(BUILD_DIR)/MDShell.bin $@ -t $(BUILD_DIR)/MDShell.Headless.SymbolTable.log -m $(SRC_DIR)/inject-tables/MDShell.Headless.txt



$(BUILD_DIR)/MDShell.SymbolTable.log: $(BUILD_DIR)/MDShell.sym | $(BUILD_DIR) $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -outopt "%s: %X"

$(BUILD_DIR)/MDShell.Headless.SymbolTable.log: $(BUILD_DIR)/MDShell.Headless.sym | $(BUILD_DIR) $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -outopt "%s: %X"


$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
