
# This Makfile shouldn't be invoked directly!

ifndef UTILS_DIR
$(error UTILS_DIR wasn't specified. Don't invoke this file directly!)
endif

CONVSYM := $(UTILS_DIR)/../build/utils/convsym
CBUNDLE := $(UTILS_DIR)/../build/utils/cbundle
BLOBTOASM := $(UTILS_DIR)/blobtoasm/blobtoasm.py

.PHONY: all

all:	$(CONVSYM) $(CBUNDLE)

$(CONVSYM):
	$(MAKE) -C $(UTILS_DIR)/convsym

$(CBUNDLE):
	$(MAKE) -C $(UTILS_DIR)/cbundle
