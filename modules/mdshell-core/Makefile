
include ../../utils/.Makefile # For $(CONVSYM), $(CBUNDLE) etc


BUILD_DIR ?= ../../build/modules/mdshell-core
SRC_DIR ?= .

SRC_FILES ?= $(wildcard $(SRC_DIR)/*.asm) $(wildcard ../errorhandler-core/*.asm) $(wildcard ../core/*.asm)

ASM68K ?= wine ../exec/asm68k.exe
ASFLAGS = /k /m /o c+,ws+,op+,os+,ow+,oz+,oaq+,osq+,omq+,ae-

.PHONY:	all release release-linkable headless clean

all:	release release-linkable headless

release:	$(BUILD_DIR)/MDShell.Blob.asm $(BUILD_DIR)/MDShell.Globals.asm

release-linkable:	$(BUILD_DIR)/MDShell.obj $(BUILD_DIR)/MDShell.Refs.asm

headless:	$(BUILD_DIR)/MDShell.Headless.Blob.asm

clean:
	rm -f $(BUILD_DIR)/*.*


# Raw unlinked binaries

$(BUILD_DIR)/MDShell.bin $(BUILD_DIR)/MDShell.sym &:	$(SRC_FILES) | $(BUILD_DIR)
	$(ASM68K) $(ASFLAGS) /p $(SRC_DIR)/MDShell.asm, $(BUILD_DIR)/MDShell.bin, $(BUILD_DIR)/MDShell.sym, $(BUILD_DIR)/MDShell.lst

$(BUILD_DIR)/MDShell.Headless.bin $(BUILD_DIR)/MDShell.Headless.sym &:	$(SRC_FILES) | $(BUILD_DIR)
	$(ASM68K) $(ASFLAGS) /p /e __HEADLESS__ $(SRC_DIR)/MDShell.asm, $(BUILD_DIR)/MDShell.Headless.bin, $(BUILD_DIR)/MDShell.Headless.sym, $(BUILD_DIR)/MDShell.Headless.lst


# ASM68K-linkable object file

$(BUILD_DIR)/MDShell.obj $(BUILD_DIR)/MDShell.Linkable.sym &:	$(SRC_FILES) | $(BUILD_DIR)
	$(ASM68K) $(ASFLAGS) /l /e __LINKABLE__ $(SRC_DIR)/MDShell.asm, $(BUILD_DIR)/MDShell.obj, $(BUILD_DIR)/MDShell.Linkable.sym, $(BUILD_DIR)/MDShell.Linkable.lst

# Global symbol tables

$(BUILD_DIR)/MDShell.Globals.asm:	$(BUILD_DIR)/MDShell.sym | $(BUILD_DIR) $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -inopt "/processLocals-" -filter "MDDBG__.+"

$(BUILD_DIR)/MDShell.Refs.asm:	$(BUILD_DIR)/MDShell.Linkable.sym | $(BUILD_DIR) $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -outopt "	xref	%s" -inopt "/processLocals-" -filter "MDDBG_.+"


# Linkable blobs in assembly format

$(BUILD_DIR)/MDShell.Blob.asm:	$(BUILD_DIR)/MDShell.bin $(BUILD_DIR)/MDShell.SymbolTable.log $(SRC_DIR)/inject-tables/MDShell.txt | $(BUILD_DIR)
	$(BLOBTOASM) $(BUILD_DIR)/MDShell.bin $@ -t $(BUILD_DIR)/MDShell.SymbolTable.log -m $(SRC_DIR)/inject-tables/MDShell.txt

$(BUILD_DIR)/MDShell.Headless.Blob.asm:	$(BUILD_DIR)/MDShell.Headless.bin $(BUILD_DIR)/MDShell.Headless.SymbolTable.log $(SRC_DIR)/inject-tables/MDShell.txt | $(BUILD_DIR)
	$(BLOBTOASM) $(BUILD_DIR)/MDShell.Headless.bin $@ -t $(BUILD_DIR)/MDShell.Headless.SymbolTable.log -m $(SRC_DIR)/inject-tables/MDShell.Headless.txt



$(BUILD_DIR)/MDShell.SymbolTable.log: $(BUILD_DIR)/MDShell.sym | $(BUILD_DIR) $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -outopt "%s: %X"

$(BUILD_DIR)/MDShell.Headless.SymbolTable.log: $(BUILD_DIR)/MDShell.Headless.sym | $(BUILD_DIR) $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -outopt "%s: %X"


$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
