
include ../../utils/.Makefile # For $(CONVSYM), $(CBUNDLE) etc


BUILD_DIR ?= ../../build/modules/debuggers
SRC_DIR ?= .

ASM68K ?= wine ../exec/asm68k.exe
ASFLAGS = /k /m /o c+ /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /o v+ /p /o ae-

.PHONY:	all backtrace clean

all:	backtrace extensions

backtrace:	$(BUILD_DIR)/Backtrace.Blob.asm

extensions:	$(BUILD_DIR)/Extensions.Blob.asm $(BUILD_DIR)/Extensions.Globals.asm

clean:
	rm -f $(BUILD_DIR)/*.*

$(BUILD_DIR)/Extensions.Globals.asm: $(BUILD_DIR)/Extensions.sym | $(CONVSYM)
	$(CONVSYM) $^ $@ -output asm -outopt "DebuggerExtensions_%s: equ DebuggerExtensions+$$%X" -inopt "/processLocals-" -filter "__global_.+"

$(BUILD_DIR)/Extensions.Blob.asm: $(BUILD_DIR)/Extensions.bin $(BUILD_DIR)/Extensions.SymbolTable.log $(SRC_DIR)/inject-tables/Extensions.txt | $(BLOBTOASM)
	$(BLOBTOASM) $(BUILD_DIR)/Extensions.bin $@ -t $(BUILD_DIR)/Extensions.SymbolTable.log -m $(SRC_DIR)/inject-tables/Extensions.txt

$(BUILD_DIR)/Extensions.bin $(BUILD_DIR)/Extensions.sym $(BUILD_DIR)/Extensions.SymbolTable.log &: $(SRC_DIR)/Extensions.asm | $(BUILD_DIR)
	$(ASM68K) $(ASFLAGS) $(SRC_DIR)/Extensions.asm, $(BUILD_DIR)/Extensions.bin, $(BUILD_DIR)/Extensions.sym, $(BUILD_DIR)/Extensions.lst
	$(CONVSYM) $(BUILD_DIR)/Extensions.sym $(BUILD_DIR)/Extensions.SymbolTable.log -output asm -outopt "%s: %X"


$(BUILD_DIR)/Backtrace.Blob.asm: $(BUILD_DIR)/Backtrace.bin $(BUILD_DIR)/Backtrace.SymbolTable.log $(SRC_DIR)/inject-tables/Backtrace.txt | $(BLOBTOASM)
	$(BLOBTOASM) $(BUILD_DIR)/Backtrace.bin $@ -t $(BUILD_DIR)/Backtrace.SymbolTable.log -m $(SRC_DIR)/inject-tables/Backtrace.txt

$(BUILD_DIR)/Backtrace.bin $(BUILD_DIR)/Backtrace.SymbolTable.log &: $(SRC_DIR)/Backtrace.asm | $(BUILD_DIR)
	$(ASM68K) $(ASFLAGS) $(SRC_DIR)/Backtrace.asm, $(BUILD_DIR)/Backtrace.bin, $(BUILD_DIR)/Backtrace.sym, $(BUILD_DIR)/Backtrace.lst
	$(CONVSYM) $(BUILD_DIR)/Backtrace.sym $(BUILD_DIR)/Backtrace.SymbolTable.log -output asm -outopt "%s: %X"


$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)
