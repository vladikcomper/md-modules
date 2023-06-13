
include ../../utils/.Makefile # For $(CONVSYM), $(CBUNDLE) etc


BUILD_DIR ?= ../../build/modules/mdshell
CORE_BUILD_DIR ?= ../../build/modules/mdshell-core
SRC_DIR ?= .

SRC_FILES = $(wildcard $(SRC_DIR)/*.asm)
CORE_SRC_FILES ?= $(wildcard ../mdshell-core/*.asm) $(wildcard ../core/*.asm)
ERRORHANDLER_FILES = $(wildcard ../errorhandler/*.asm)


.PHONY:	all asm68k as headless tests clean

all:	asm68k as headless

asm68k:	$(BUILD_DIR)/asm68k/MDShell.asm

as:	$(BUILD_DIR)/as/MDShell.asm

headless:	$(BUILD_DIR)/headless/MDShell.asm

tests:	asm68k as headless
	make -C tests -f .Makefile

clean:
	rm -rf $(BUILD_DIR)/*


$(BUILD_DIR)/asm68k/MDShell.asm:	$(SRC_FILES) $(ERRORHANDLER_FILES) $(BUILD_DIR)/MDShell.Global.ASM68K.asm $(BUILD_DIR)/MDShell.Blob.asm | $(BUILD_DIR) $(CBUNDLE)
	mkdir -p $(BUILD_DIR)/asm68k
	$(CBUNDLE) $(SRC_DIR)/MDShell.asm -def MD-SHELL -def BUNDLE-ASM68K -out $@

$(BUILD_DIR)/as/MDShell.asm:	$(SRC_FILES) $(ERRORHANDLER_FILES) $(BUILD_DIR)/MDShell.Global.AS.asm $(BUILD_DIR)/MDShell.Blob.asm | $(BUILD_DIR) $(CBUNDLE)
	mkdir -p $(BUILD_DIR)/as
	$(CBUNDLE) $(SRC_DIR)/MDShell.asm -def MD-SHELL -def BUNDLE-AS -out $@

$(BUILD_DIR)/headless/MDShell.asm:	$(SRC_FILES) $(ERRORHANDLER_FILES) $(BUILD_DIR)/MDShell.Blob.asm | $(BUILD_DIR) $(CBUNDLE)
	mkdir -p $(BUILD_DIR)/headless
	$(CBUNDLE) $(SRC_DIR)/MDShell.asm -def MD-SHELL -def HEADLESS -out $@

$(BUILD_DIR)/MDShell.Blob.asm:	$(CORE_BUILD_DIR)/MDShell.bin $(BUILD_DIR)/MDShell.InjectTable.log $(SRC_DIR)/MDShell.InjectData.log | $(BUILD_DIR)
	$(BLOBTOASM) $(CORE_BUILD_DIR)/MDShell.bin $@ -t $(BUILD_DIR)/MDShell.InjectTable.log -m $(SRC_DIR)/MDShell.InjectData.log

$(BUILD_DIR)/MDShell.Global.ASM68K.asm:	$(CORE_BUILD_DIR)/MDShell.sym | $(BUILD_DIR) $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -outopt "ErrorHandler.%s equ $$%X" -filter "__global_.+"

$(BUILD_DIR)/MDShell.Global.AS.asm:	$(CORE_BUILD_DIR)/MDShell.sym | $(BUILD_DIR) $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -outopt "ErrorHandler_%s label $$%X" -filter "__global_.+"

$(BUILD_DIR)/MDShell.InjectTable.log: $(CORE_BUILD_DIR)/MDShell.sym | $(BUILD_DIR) $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -outopt "%s: %X" -filter "__(inject|blob)_.+"

$(CORE_BUILD_DIR)/MDShell.sym $(CORE_BUILD_DIR)/MDShell.bin &: $(CORE_SRC_FILES)
	make -C ../mdshell-core

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
