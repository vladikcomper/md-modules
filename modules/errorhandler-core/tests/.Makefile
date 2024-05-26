
# WARNING! It's not recommended to invoke this Makefile manually, since it doesn't track test dependencies.
# Please run `make tests` from the upper directory instead.

include ../../../utils/.Makefile # For $(CONVSYM), $(CBUNDLE) etc

ASM68K := wine $(realpath ../../exec/asm68k.exe)
ASFLAGS := /q /k /m /o c+,ws+,op+,os+,ow+,oz+,oaq+,osq+,omq+,ae-,v+

TEST_BUILD_DIR := ../../../build/modules/errorhandler-core/tests



.PHONY:	all formatstring fullexception guesscaller clean

all:	formatstring fullexception guesscaller

clean:
	rm -f $(TEST_BUILD_DIR)/*


formatstring:	| $(TEST_BUILD_DIR) $(CONVSYM)
	$(ASM68K) $(ASFLAGS) /p FormatString.asm, $(TEST_BUILD_DIR)/FormatString.gen, $(TEST_BUILD_DIR)/FormatString.sym, $(TEST_BUILD_DIR)/FormatString.lst
	$(CONVSYM) FormatString_DummySymbols.log $(TEST_BUILD_DIR)/FormatString.gen -a -range 0 FFFFFF -input log -output deb2
	$(CONVSYM) $(TEST_BUILD_DIR)/FormatString.sym $(TEST_BUILD_DIR)/FormatString.gen -a -ref 200

fullexception:	| $(TEST_BUILD_DIR) $(CONVSYM)
	cd .. && $(ASM68K) $(ASFLAGS) /p tests/FullException.asm, tests/$(TEST_BUILD_DIR)/FullException.gen, tests/$(TEST_BUILD_DIR)/FullException.sym, tests/$(TEST_BUILD_DIR)/FullException.lst
	$(CONVSYM) $(TEST_BUILD_DIR)/FullException.sym $(TEST_BUILD_DIR)/FullException.gen -a

guesscaller:	| $(TEST_BUILD_DIR) $(CONVSYM)
	cd .. && $(ASM68K) $(ASFLAGS) /p tests/GuessCaller.asm, tests/$(TEST_BUILD_DIR)/GuessCaller.gen, tests/$(TEST_BUILD_DIR)/GuessCaller.sym, tests/$(TEST_BUILD_DIR)/GuessCaller.lst
	$(CONVSYM) $(TEST_BUILD_DIR)/GuessCaller.sym $(TEST_BUILD_DIR)/GuessCaller.gen -a -ref 200


$(TEST_BUILD_DIR):
	mkdir -p $(TEST_BUILD_DIR)
