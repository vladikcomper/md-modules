
UTILS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

# On Windows, executables end with .exe
ifeq ($(OS), Windows NT)
	CONVSYM := $(UTILS_DIR)/../build/utils/convsym.exe
	CBUNDLE := $(UTILS_DIR)/../build/utils/cbundle.exe
	BLOB2ASM := $(UTILS_DIR)/blob2asm/blob2asm.py
else
	CONVSYM := $(UTILS_DIR)/../build/utils/convsym
	CBUNDLE := $(UTILS_DIR)/../build/utils/cbundle
	BLOBTOASM := $(UTILS_DIR)/blobtoasm/blobtoasm.py
endif

.PHONY: all

all:	$(CONVSYM) $(CBUNDLE) $(BLOB2ASM)

$(CONVSYM):
	make -C $(UTILS_DIR)/convsym

$(CBUNDLE):
	make -C $(UTILS_DIR)/cbundle
