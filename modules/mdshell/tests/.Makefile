
# WARNING! It's not recommended to invoke this Makefile manually, since it doesn't track test dependencies.
# Please run `make tests` from the upper directory instead.

include ../../../utils/.Makefile # For $(CONVSYM), $(CBUNDLE) etc

ASM68K := wine ../../exec/asm68k.exe
ASL := wine ../../exec/as/asl.exe
P2BIN := wine ../../exec/as/p2bin.exe

TEST_BUILD_DIR ?= ../../../build/modules/mdshell/tests



.PHONY:	all hello-world flow-test clean

all:	hello-world flow-test

clean:
	rm -f $(TEST_BUILD_DIR)/*


hello-world:	| $(TEST_BUILD_DIR) $(CONVSYM)
	$(ASM68K) /k /m /o c+ /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- hello-world.asm, $(TEST_BUILD_DIR)/hello-world.gen, $(TEST_BUILD_DIR)/hello-world.sym, $(TEST_BUILD_DIR)/hello-world.lst
	$(CONVSYM) $(TEST_BUILD_DIR)/hello-world.sym $(TEST_BUILD_DIR)/hello-world.gen -a -ref 200 -debug


flow-test:	| $(TEST_BUILD_DIR) $(CONVSYM) $(CBUNDLE)
	$(CBUNDLE) flow-test.asm -def ASM68K -out $(TEST_BUILD_DIR)/flow-test-asm68k.asm
	$(CBUNDLE) flow-test.asm -def AS -out $(TEST_BUILD_DIR)/flow-test-as.asm

	$(ASM68K) /k /m /o c+ /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- $(TEST_BUILD_DIR)/flow-test-asm68k.asm, $(TEST_BUILD_DIR)/flow-test-asm68k.gen, $(TEST_BUILD_DIR)/flow-test-asm68k.sym, $(TEST_BUILD_DIR)/flow-test-asm68k.lst
	$(CONVSYM) $(TEST_BUILD_DIR)/flow-test-asm68k.sym $(TEST_BUILD_DIR)/flow-test-asm68k.gen -in asm68k_sym -a -ref 200 -debug
	
	set AS_MSGPATH="..\..\exec\as"
	set USEANSI=n
	$(ASL) -xx -A -L -OLIST $(TEST_BUILD_DIR)/flow-test-as.lst $(TEST_BUILD_DIR)/flow-test-as.asm -o $(TEST_BUILD_DIR)/flow-test-as.p
	$(P2BIN) $(TEST_BUILD_DIR)/flow-test-as.p $(TEST_BUILD_DIR)/flow-test-as.gen -r 0x-0x
	rm $(TEST_BUILD_DIR)/flow-test-as.p
	$(CONVSYM) $(TEST_BUILD_DIR)/flow-test-as.lst $(TEST_BUILD_DIR)/flow-test-as.gen -in as_lst -a -ref 200


$(TEST_BUILD_DIR):
	mkdir -p $(TEST_BUILD_DIR)
