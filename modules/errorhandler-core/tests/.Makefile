
# WARNING! It's not recommended to invoke this Makefile manually, since it doesn't track test dependencies.
# Please run `make tests` from the upper directory instead.

include ../../../utils/.Makefile # For $(CONVSYM), $(CBUNDLE) etc

ASM68K := wine $(realpath ../../exec/asm68k.exe)

TEST_BUILD_DIR := $(realpath ../../../build/modules/errorhandler-core/tests)



.PHONY:	all formatstring fullexception guesscaller clean

all:	formatstring fullexception guesscaller

clean:
	rm -f $(TEST_BUILD_DIR)/*


formatstring:	| $(TEST_BUILD_DIR) $(CONVSYM)
	$(ASM68K) /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- FormatString.asm, $(TEST_BUILD_DIR)/FormatString.gen, $(TEST_BUILD_DIR)/FormatString.sym, $(TEST_BUILD_DIR)/FormatString.lst
	$(CONVSYM) FormatString_DummySymbols.log $(TEST_BUILD_DIR)/FormatString.gen -a -range 0 FFFFFF -input log -output deb2 -ref 200

fullexception:	| $(TEST_BUILD_DIR) $(CONVSYM)
	cd .. && $(ASM68K) /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- tests/FullException.asm, $(TEST_BUILD_DIR)/FullException.gen, $(TEST_BUILD_DIR)/FullException.sym, $(TEST_BUILD_DIR)/FullException.lst
	$(CONVSYM) $(TEST_BUILD_DIR)/FullException.sym $(TEST_BUILD_DIR)/FullException.gen -a

guesscaller:	| $(TEST_BUILD_DIR) $(CONVSYM)
	cd .. && $(ASM68K) /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- tests/GuessCaller.asm, $(TEST_BUILD_DIR)/GuessCaller.gen, $(TEST_BUILD_DIR)/GuessCaller.sym, $(TEST_BUILD_DIR)/GuessCaller.lst
	$(CONVSYM) $(TEST_BUILD_DIR)/GuessCaller.sym $(TEST_BUILD_DIR)/GuessCaller.gen -a -ref 200


$(TEST_BUILD_DIR):
	mkdir -p $(TEST_BUILD_DIR)
