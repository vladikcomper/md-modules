
include ../../utils/.Makefile # For $(CONVSYM), $(CBUNDLE) etc


BUILD_DIR ?= ../../build/modules/mdshell
CORE_BUILD_DIR ?= ../../build/modules/mdshell-core
EXT_BUILD_DIR ?= ../../build/modules/debuggers
SRC_DIR ?= .

SRC_FILES = $(wildcard $(SRC_DIR)/*.asm)
CORE_SRC_FILES ?= $(wildcard ../mdshell-core/*.asm) $(wildcard ../core/*.asm)
EH_SRC_FILES = $(wildcard ../errorhandler/*.asm)
EH_CORE_SRC_FILES = $(wildcard ../errorhandler-core/*.asm) $(wildcard ../core/*.asm)
EXT_SRC_FILES ?= $(wildcard ../debuggers/*.asm) $(wildcard ../core/*.asm)


.PHONY:	all asm68k as headless tests clean

all:	asm68k as headless

asm68k:	$(BUILD_DIR)/asm68k/MDShell.asm

as:	$(BUILD_DIR)/as/MDShell.asm

headless:	$(BUILD_DIR)/headless/MDShell.asm

tests:	asm68k as headless
	$(MAKE) -C tests -f .Makefile

clean:
	rm -rf $(BUILD_DIR)/*


$(BUILD_DIR)/asm68k/MDShell.asm:	$(SRC_FILES) $(EH_SRC_FILES) $(CORE_BUILD_DIR)/MDShell.Globals.asm $(CORE_BUILD_DIR)/MDShell.Blob.asm $(EXT_BUILD_DIR)/Extensions.Blob.asm $(EXT_BUILD_DIR)/Backtrace.Blob.asm $(EXT_BUILD_DIR)/AddressRegisters.Blob.asm | $(BUILD_DIR) $(CBUNDLE)
	mkdir -p $(BUILD_DIR)/asm68k
	$(CBUNDLE) $(SRC_DIR)/MDShell.asm -def MD-SHELL -def BUNDLE-ASM68K -out $@

$(BUILD_DIR)/as/MDShell.asm:	$(SRC_FILES) $(EH_SRC_FILES) $(CORE_BUILD_DIR)/MDShell.Globals.asm $(CORE_BUILD_DIR)/MDShell.Blob.asm $(EXT_BUILD_DIR)/Extensions.Blob.asm $(EXT_BUILD_DIR)/Backtrace.Blob.asm $(EXT_BUILD_DIR)/AddressRegisters.Blob.asm | $(BUILD_DIR) $(CBUNDLE)
	mkdir -p $(BUILD_DIR)/as
	$(CBUNDLE) $(SRC_DIR)/MDShell.asm -def MD-SHELL -def BUNDLE-AS -out $@

$(BUILD_DIR)/headless/MDShell.asm:	$(SRC_FILES) $(EH_SRC_FILES) $(CORE_BUILD_DIR)/MDShell.Headless.Blob.asm | $(BUILD_DIR) $(CBUNDLE)
	mkdir -p $(BUILD_DIR)/headless
	$(CBUNDLE) $(SRC_DIR)/MDShell.Headless.asm -def MD-SHELL -def HEADLESS -out $@



$(CORE_BUILD_DIR)/MDShell.Globals.asm $(CORE_BUILD_DIR)/MDShell.Blob.asm &: $(CORE_SRC_FILES) $(EH_CORE_SRC_FILES)
	$(MAKE) -C ../mdshell-core release

$(CORE_BUILD_DIR)/MDShell.Headless.Blob.asm &: $(CORE_SRC_FILES) $(EH_CORE_SRC_FILES)
	$(MAKE) -C ../mdshell-core headless


$(EXT_BUILD_DIR)/Extensions.Blob.asm:	$(EXT_SRC_FILES)
	$(MAKE) -C ../debuggers extensions

$(EXT_BUILD_DIR)/Backtrace.Blob.asm:	$(EXT_SRC_FILES)
	$(MAKE) -C ../debuggers backtrace

$(EXT_BUILD_DIR)/AddressRegisters.Blob.asm:	$(EXT_SRC_FILES)
	$(MAKE) -C ../debuggers address


$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
