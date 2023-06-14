
# WARNING! Please don't invoke this Makefile directly

UTILS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

CONVSYM := $(UTILS_DIR)/../build/utils/convsym
CBUNDLE := $(UTILS_DIR)/../build/utils/cbundle
BLOBTOASM := $(UTILS_DIR)/blobtoasm/blobtoasm.py

.PHONY: all

all:	$(CONVSYM) $(CBUNDLE)

$(CONVSYM):
	gmake -C $(UTILS_DIR)/convsym

$(CBUNDLE):
	gmake -C $(UTILS_DIR)/cbundle
