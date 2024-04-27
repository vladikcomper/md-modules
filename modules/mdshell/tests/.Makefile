
# WARNING! It's not recommended to invoke this Makefile manually, since it doesn't track test dependencies.
# Please run `make tests` from the upper directory instead.

include ../../../utils/.Makefile # For $(CONVSYM), $(CBUNDLE) etc

ASM68K := wine ../../exec/asm68k.exe
PSYLINK := wine ../../exec/psylink.exe
ASL := wine ../../exec/as/asl.exe
P2BIN := wine ../../exec/as/p2bin.exe

TEST_BUILD_DIR := ../../../build/modules/mdshell/tests

BUILD_DIR := ../../../build/modules/mdshell


.PHONY:	all hello-world flow-test raise-error linkable clean

all:	hello-world flow-test raise-error linkable

clean:
	rm -f $(TEST_BUILD_DIR)/*


hello-world:	| $(TEST_BUILD_DIR) $(CONVSYM)
	$(ASM68K) /k /m /o c+,ws+,op+,os+,ow+,oz+,oaq+,osq+,omq+,ae- /p hello-world.asm, $(TEST_BUILD_DIR)/hello-world.gen, $(TEST_BUILD_DIR)/hello-world.sym, $(TEST_BUILD_DIR)/hello-world.lst
	$(CONVSYM) $(TEST_BUILD_DIR)/hello-world.sym $(TEST_BUILD_DIR)/hello-world.gen -a -ref 200 -debug


raise-error:	| $(TEST_BUILD_DIR) $(CONVSYM)
	$(ASM68K) /k /m /o c+,ws+,op+,os+,ow+,oz+,oaq+,osq+,omq+,ae- /p raise-error.asm, $(TEST_BUILD_DIR)/raise-error.gen, $(TEST_BUILD_DIR)/raise-error.sym, $(TEST_BUILD_DIR)/raise-error.lst
	$(CONVSYM) $(TEST_BUILD_DIR)/raise-error.sym $(TEST_BUILD_DIR)/raise-error.gen -a -ref 200 -debug


linkable:	| $(TEST_BUILD_DIR) $(MDSHELL_HEADLESS) $(CONVSYM)
	$(ASM68K) /k /m /o c+,ws+,op+,os+,ow+,oz+,oaq+,osq+,omq+,ae- /g /l linkable.asm, $(TEST_BUILD_DIR)/linkable.obj, , $(TEST_BUILD_DIR)/linkable.lst
	$(PSYLINK) /p $(BUILD_DIR)/asm68k-linkable/MDShell.obj $(TEST_BUILD_DIR)/linkable.obj,$(TEST_BUILD_DIR)/linkable.gen,$(TEST_BUILD_DIR)/linkable.sym
	$(CONVSYM) $(TEST_BUILD_DIR)/linkable.sym $(TEST_BUILD_DIR)/linkable.gen -input asm68k_sym -output deb2 -a -ref 200


flow-test:	| $(TEST_BUILD_DIR) $(CONVSYM) $(CBUNDLE)
	$(CBUNDLE) flow-test.asm -def ASM68K -out $(TEST_BUILD_DIR)/flow-test-asm68k.asm
	$(CBUNDLE) flow-test.asm -def AS -out $(TEST_BUILD_DIR)/flow-test-as.asm

	$(ASM68K) /k /m /o c+,ws+,op+,os+,ow+,oz+,oaq+,osq+,omq+,ae-,l+ /p $(TEST_BUILD_DIR)/flow-test-asm68k.asm, $(TEST_BUILD_DIR)/flow-test-asm68k.gen, $(TEST_BUILD_DIR)/flow-test-asm68k.sym, $(TEST_BUILD_DIR)/flow-test-asm68k.lst
	$(CONVSYM) $(TEST_BUILD_DIR)/flow-test-asm68k.sym $(TEST_BUILD_DIR)/flow-test-asm68k.gen -in asm68k_sym -a -ref 200 -debug
	
	set AS_MSGPATH="..\..\exec\as"
	set USEANSI=n
	$(ASL) -xx -A -L -OLIST $(TEST_BUILD_DIR)/flow-test-as.lst $(TEST_BUILD_DIR)/flow-test-as.asm -o $(TEST_BUILD_DIR)/flow-test-as.p
	$(P2BIN) $(TEST_BUILD_DIR)/flow-test-as.p $(TEST_BUILD_DIR)/flow-test-as.gen -r 0x-0x
	rm $(TEST_BUILD_DIR)/flow-test-as.p
	$(CONVSYM) $(TEST_BUILD_DIR)/flow-test-as.lst $(TEST_BUILD_DIR)/flow-test-as.gen -in as_lst -a -ref 200


$(TEST_BUILD_DIR):
	mkdir -p $(TEST_BUILD_DIR)
