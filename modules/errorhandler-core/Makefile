
include ../../utils/.Makefile # For $(CONVSYM), $(CBUNDLE) etc


BUILD_DIR ?= ../../build/modules/errorhandler-core
SRC_DIR ?= .
CORE_DIR ?= ../core

ASM68K ?= wine ../exec/asm68k.exe
ASFLAGS := /q /k /m /o c+,ws+,op+,os+,ow+,oz+,oaq+,osq+,omq+,ae-

.PHONY:	all release release-linkable headless debug extsym tests clean

all:	release release-linkable headless debug extsym

release:	$(BUILD_DIR)/ErrorHandler.bin $(BUILD_DIR)/ErrorHandler.Blob.asm $(BUILD_DIR)/ErrorHandler.Globals.asm

release-linkable:	$(BUILD_DIR)/ErrorHandler.Linkable.obj $(BUILD_DIR)/ErrorHandler.Linkable.Refs.asm

headless:	$(BUILD_DIR)/ErrorHandler.Headless.bin $(BUILD_DIR)/ErrorHandler.Headless.SymbolTable.log

debug:	$(BUILD_DIR)/ErrorHandler.Debug.bin $(BUILD_DIR)/ErrorHandler.Debug.Blob.asm $(BUILD_DIR)/ErrorHandler.Debug.Globals.asm

# "extsym" build is usuable in assembly blob form only, because it requires additional linkage
extsym:	$(BUILD_DIR)/ErrorHandler.ExtSymbols.Blob.asm $(BUILD_DIR)/ErrorHandler.ExtSymbols.Globals.asm


tests:	release	debug extsym
	$(MAKE) -C ../mdshell
	$(MAKE) -C tests -f .Makefile

clean:
	rm -f $(BUILD_DIR)/*.*

# ASM68K-linkable object file

$(BUILD_DIR)/ErrorHandler.Linkable.obj $(BUILD_DIR)/ErrorHandler.Linkable.sym &:	$(wildcard $(SRC_DIR)/*.asm) $(wildcard $(CORE_DIR)/*.asm) | $(BUILD_DIR)
	$(ASM68K) $(ASFLAGS) /l /e __LINKABLE__ $(SRC_DIR)/Main.asm, $(BUILD_DIR)/ErrorHandler.Linkable.obj, $(BUILD_DIR)/ErrorHandler.Linkable.sym, $(BUILD_DIR)/ErrorHandler.Linkable.lst

# Raw unlinked binaries

$(BUILD_DIR)/ErrorHandler.bin $(BUILD_DIR)/ErrorHandler.sym &:	$(wildcard $(SRC_DIR)/*.asm) $(wildcard $(CORE_DIR)/*.asm) | $(BUILD_DIR)
	$(ASM68K) $(ASFLAGS) /p $(SRC_DIR)/Main.asm, $(BUILD_DIR)/ErrorHandler.bin, $(BUILD_DIR)/ErrorHandler.sym, $(BUILD_DIR)/ErrorHandler.lst

$(BUILD_DIR)/ErrorHandler.Debug.bin $(BUILD_DIR)/ErrorHandler.Debug.sym &:	$(wildcard $(SRC_DIR)/*.asm) $(wildcard $(CORE_DIR)/*.asm) | $(BUILD_DIR)
	$(ASM68K) $(ASFLAGS) /p /e __DEBUG__ $(SRC_DIR)/Main.asm, $(BUILD_DIR)/ErrorHandler.Debug.bin, $(BUILD_DIR)/ErrorHandler.Debug.sym, $(BUILD_DIR)/ErrorHandler.Debug.lst

$(BUILD_DIR)/ErrorHandler.ExtSymbols.bin $(BUILD_DIR)/ErrorHandler.ExtSymbols.sym &:	$(wildcard $(SRC_DIR)/*.asm) $(wildcard $(CORE_DIR)/*.asm) | $(BUILD_DIR)
	$(ASM68K) $(ASFLAGS) /p /e __EXTSYM__ /e SymbolData_Ptr=0 $(SRC_DIR)/Main.asm, $(BUILD_DIR)/ErrorHandler.ExtSymbols.bin, $(BUILD_DIR)/ErrorHandler.ExtSymbols.sym, $(BUILD_DIR)/ErrorHandler.ExtSymbols.lst

$(BUILD_DIR)/ErrorHandler.Headless.bin $(BUILD_DIR)/ErrorHandler.Headless.sym &:	$(wildcard $(SRC_DIR)/*.asm) $(wildcard $(CORE_DIR)/*.asm) | $(BUILD_DIR)
	$(ASM68K) $(ASFLAGS) /p /e __HEADLESS__ $(SRC_DIR)/Main.asm, $(BUILD_DIR)/ErrorHandler.Headless.bin, $(BUILD_DIR)/ErrorHandler.Headless.sym, $(BUILD_DIR)/ErrorHandler.Headless.lst


# Symbol tables

$(BUILD_DIR)/ErrorHandler.Globals.asm:	$(BUILD_DIR)/ErrorHandler.sym | $(BUILD_DIR) $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -outopt "%s: equ ErrorHandler+$$%X" -inopt "/processLocals-" -filter "MDDBG_.+"

$(BUILD_DIR)/ErrorHandler.Debug.Globals.asm:	$(BUILD_DIR)/ErrorHandler.Debug.sym | $(BUILD_DIR) $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -outopt "%s: equ ErrorHandler+$$%X" -inopt "/processLocals-" -filter "MDDBG_.+"

$(BUILD_DIR)/ErrorHandler.ExtSymbols.Globals.asm:	$(BUILD_DIR)/ErrorHandler.ExtSymbols.sym | $(BUILD_DIR) $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -outopt "%s: equ ErrorHandler+$$%X" -inopt "/processLocals-" -filter "MDDBG_.+"

$(BUILD_DIR)/ErrorHandler.Linkable.Refs.asm:	$(BUILD_DIR)/ErrorHandler.Linkable.sym | $(BUILD_DIR) $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -outopt "	xref	%s" -inopt "/processLocals-" -filter "MDDBG_.+"


# Linkable blobs in assembly format

$(BUILD_DIR)/ErrorHandler.Blob.asm:	$(BUILD_DIR)/ErrorHandler.bin $(BUILD_DIR)/ErrorHandler.SymbolTable.log | $(BUILD_DIR)
	$(BLOBTOASM) $(BUILD_DIR)/ErrorHandler.bin $@ -m $(SRC_DIR)/inject-tables/ErrorHandler.Blob.txt -t $(BUILD_DIR)/ErrorHandler.SymbolTable.log

$(BUILD_DIR)/ErrorHandler.Debug.Blob.asm:	$(BUILD_DIR)/ErrorHandler.Debug.bin $(BUILD_DIR)/ErrorHandler.Debug.SymbolTable.log | $(BUILD_DIR)
	$(BLOBTOASM) $(BUILD_DIR)/ErrorHandler.Debug.bin $@ -m $(SRC_DIR)/inject-tables/ErrorHandler.Blob.txt -t $(BUILD_DIR)/ErrorHandler.Debug.SymbolTable.log

$(BUILD_DIR)/ErrorHandler.ExtSymbols.Blob.asm:	$(BUILD_DIR)/ErrorHandler.ExtSymbols.bin $(BUILD_DIR)/ErrorHandler.ExtSymbols.SymbolTable.log | $(BUILD_DIR)
	$(BLOBTOASM) $(BUILD_DIR)/ErrorHandler.ExtSymbols.bin $@ -m $(SRC_DIR)/inject-tables/ErrorHandler.ExtSymbols.Blob.txt -t $(BUILD_DIR)/ErrorHandler.ExtSymbols.SymbolTable.log

# Symbols tables for Blob2Asm utility (poor man's linker)

$(BUILD_DIR)/ErrorHandler.SymbolTable.log:	$(BUILD_DIR)/ErrorHandler.sym | $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -inopt "/processLocals-" -outopt "%s: %X"

$(BUILD_DIR)/ErrorHandler.Debug.SymbolTable.log:	$(BUILD_DIR)/ErrorHandler.Debug.sym | $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -inopt "/processLocals-" -outopt "%s: %X"

$(BUILD_DIR)/ErrorHandler.ExtSymbols.SymbolTable.log:	$(BUILD_DIR)/ErrorHandler.ExtSymbols.sym | $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -inopt "/processLocals-" -outopt "%s: %X"

$(BUILD_DIR)/ErrorHandler.Headless.SymbolTable.log:	$(BUILD_DIR)/ErrorHandler.Headless.sym | $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -inopt "/processLocals-" -outopt "%s: %X"

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
