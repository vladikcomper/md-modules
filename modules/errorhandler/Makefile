
include ../../utils/Makefile # For $(CONVSYM), $(CBUNDLE) etc


BUILD_DIR ?= ../../build/modules/errorhandler
CORE_BUILD_DIR ?= ../../build/modules/errorhandler-core
SRC_DIR ?= .

SRC_FILES = $(wildcard $(SRC_DIR)/*.asm)
CORE_SRC_FILES ?= $(wildcard ../errorhandler-core/*.asm) $(wildcard ../core/*.asm)


.PHONY:	all asm68k asm68k-debug asm68k-extsym as as-extsym clean

all:	asm68k asm68k-debug asm68k-extsym as as-extsym

asm68k:	$(BUILD_DIR)/asm68k/Debugger.asm $(BUILD_DIR)/asm68k/ErrorHandler.asm

asm68k-debug:	$(BUILD_DIR)/asm68k-debug/Debugger.asm $(BUILD_DIR)/asm68k-debug/ErrorHandler.asm

asm68k-extsym:	$(BUILD_DIR)/asm68k-extsym/Debugger.asm $(BUILD_DIR)/asm68k-extsym/ErrorHandler.asm

as:	$(BUILD_DIR)/as/Debugger.asm $(BUILD_DIR)/as/ErrorHandler.asm

as-extsym:	$(BUILD_DIR)/as-extsym/Debugger.asm $(BUILD_DIR)/as-extsym/ErrorHandler.asm

clean:
	rm -rf $(BUILD_DIR)/*


$(BUILD_DIR)/asm68k/Debugger.asm $(BUILD_DIR)/asm68k/ErrorHandler.asm &:	$(SRC_FILES) $(BUILD_DIR)/ErrorHandler.Blob.asm $(BUILD_DIR)/ErrorHandler.Global.ASM68K.asm | $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/asm68k
	$(CBUNDLE) $(SRC_DIR)/Debugger.asm -def BUNDLE-ASM68K -out $(BUILD_DIR)/asm68k/Debugger.asm
	$(CBUNDLE) $(SRC_DIR)/ErrorHandler.asm -def BUNDLE-ASM68K -out $(BUILD_DIR)/asm68k/ErrorHandler.asm

$(BUILD_DIR)/asm68k-debug/Debugger.asm $(BUILD_DIR)/asm68k-debug/ErrorHandler.asm &: $(SRC_FILES) $(BUILD_DIR)/ErrorHandler.Debug.Blob.asm $(BUILD_DIR)/ErrorHandler.Debug.Global.ASM68K.asm | $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/asm68k-debug
	$(CBUNDLE) $(SRC_DIR)/Debugger.asm -def BUNDLE-ASM68K -def DEBUG -out $(BUILD_DIR)/asm68k-debug/Debugger.asm
	$(CBUNDLE) $(SRC_DIR)/ErrorHandler.asm -def BUNDLE-ASM68K -def DEBUG -out $(BUILD_DIR)/asm68k-debug/ErrorHandler.asm

$(BUILD_DIR)/asm68k-extsym/Debugger.asm $(BUILD_DIR)/asm68k-extsym/ErrorHandler.asm &: $(SRC_FILES) $(BUILD_DIR)/ErrorHandler.ExtSymbols.Blob.asm $(BUILD_DIR)/ErrorHandler.ExtSymbols.Global.ASM68K.asm | $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/asm68k-extsym
	$(CBUNDLE) $(SRC_DIR)/Debugger.asm -def BUNDLE-ASM68K -def EXTSYM -out $(BUILD_DIR)/asm68k-extsym/Debugger.asm
	$(CBUNDLE) $(SRC_DIR)/ErrorHandler.asm -def BUNDLE-ASM68K -def EXTSYM -out $(BUILD_DIR)/asm68k-extsym/ErrorHandler.asm

$(BUILD_DIR)/as/Debugger.asm $(BUILD_DIR)/as/ErrorHandler.asm &: $(SRC_FILES) $(BUILD_DIR)/ErrorHandler.Blob.asm $(BUILD_DIR)/ErrorHandler.Global.AS.asm | $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/as
	$(CBUNDLE) $(SRC_DIR)/Debugger.asm -def BUNDLE-AS -out $(BUILD_DIR)/as/Debugger.asm
	$(CBUNDLE) $(SRC_DIR)/ErrorHandler.asm -def BUNDLE-AS -out $(BUILD_DIR)/as/ErrorHandler.asm

$(BUILD_DIR)/as-extsym/Debugger.asm $(BUILD_DIR)/as-extsym/ErrorHandler.asm &: $(SRC_FILES) $(BUILD_DIR)/ErrorHandler.ExtSymbols.Blob.asm $(BUILD_DIR)/ErrorHandler.ExtSymbols.Global.AS.asm | $(BUILD_DIR)
	mkdir -p $(BUILD_DIR)/as-extsym
	$(CBUNDLE) $(SRC_DIR)/Debugger.asm -def BUNDLE-AS -def EXTSYM -out $(BUILD_DIR)/as-extsym/Debugger.asm
	$(CBUNDLE) $(SRC_DIR)/ErrorHandler.asm -def BUNDLE-AS -def EXTSYM -out $(BUILD_DIR)/as-extsym/ErrorHandler.asm


$(BUILD_DIR)/ErrorHandler.Global.ASM68K.asm:	$(CORE_BUILD_DIR)/ErrorHandler.sym | $(BUILD_DIR) $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -outopt "ErrorHandler.%s equ ErrorHandler_+$$%X" -inopt "/processLocals-" -filter "__global_.+"

$(BUILD_DIR)/ErrorHandler.Debug.Global.ASM68K.asm:	$(CORE_BUILD_DIR)/ErrorHandler.Debug.sym | $(BUILD_DIR) $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -outopt "ErrorHandler.%s: equ ErrorHandler+$$%X" -inopt "/processLocals-" -filter "__global_.+"

$(BUILD_DIR)/ErrorHandler.ExtSymbols.Global.ASM68K.asm:	$(CORE_BUILD_DIR)/ErrorHandler.ExtSymbols.sym | $(BUILD_DIR) $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -outopt "ErrorHandler.%s: equ ErrorHandler+$$%X" -inopt "/processLocals-" -filter "__global_.+"

$(BUILD_DIR)/ErrorHandler.Global.AS.asm:	$(CORE_BUILD_DIR)/ErrorHandler.sym | $(BUILD_DIR) $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -outopt "ErrorHandler_%s label ErrorHandler_+$$%X" -inopt "/processLocals-" -filter "__global_.+"

$(BUILD_DIR)/ErrorHandler.ExtSymbols.Global.AS.asm:	$(CORE_BUILD_DIR)/ErrorHandler.ExtSymbols.sym | $(BUILD_DIR) $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -outopt "ErrorHandler_%s label ErrorHandler_+$$%X" -inopt "/processLocals-" -filter "__global_.+"


$(BUILD_DIR)/ErrorHandler.Blob.asm:	$(CORE_BUILD_DIR)/ErrorHandler.bin | $(BUILD_DIR)
	$(BLOBTOASM) $(CORE_BUILD_DIR)/ErrorHandler.bin $@

$(BUILD_DIR)/ErrorHandler.Debug.Blob.asm:	$(CORE_BUILD_DIR)/ErrorHandler.Debug.bin | $(BUILD_DIR)
	$(BLOBTOASM) $(CORE_BUILD_DIR)/ErrorHandler.Debug.bin $@

$(BUILD_DIR)/ErrorHandler.ExtSymbols.Blob.asm:	$(CORE_BUILD_DIR)/ErrorHandler.ExtSymbols.bin $(BUILD_DIR)/ErrorHandler.ExtSymbols.InjectTable.log | $(BUILD_DIR)
	$(BLOBTOASM) $(CORE_BUILD_DIR)/ErrorHandler.ExtSymbols.bin $@ -m $(SRC_DIR)/ErrorHandler.ExtSymbols.InjectData.txt -t $(BUILD_DIR)/ErrorHandler.ExtSymbols.InjectTable.log


$(BUILD_DIR)/ErrorHandler.ExtSymbols.InjectTable.log:	$(CORE_BUILD_DIR)/ErrorHandler.ExtSymbols.sym | $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -inopt "/processLocals-" -outopt "%s: %X" -filter '__inject_.+'


$(CORE_BUILD_DIR)/ErrorHandler.bin $(CORE_BUILD_DIR)/ErrorHandler.sym &:	$(CORE_SRC_FILES)
	make -C ../errorhandler-core release

$(CORE_BUILD_DIR)/ErrorHandler.Debug.bin  $(CORE_BUILD_DIR)/ErrorHandler.Debug.sym &:	$(CORE_SRC_FILES)
	make -C ../errorhandler-core debug

$(CORE_BUILD_DIR)/ErrorHandler.ExtSymbols.bin  $(CORE_BUILD_DIR)/ErrorHandler.ExtSymbols.sym &:	$(CORE_SRC_FILES)
	make -C ../errorhandler-core extsym


$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
