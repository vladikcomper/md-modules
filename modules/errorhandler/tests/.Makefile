
# WARNING! It's not recommended to invoke this Makefile manually, since it doesn't track test dependencies.
# Please run `make tests` from the upper directory instead.

include ../../../utils/.Makefile # For $(CONVSYM), $(CBUNDLE) etc

ASM68K := wine ../../exec/asm68k.exe
PSYLINK := wine ../../exec/psylink.exe
ASL := wine ../../exec/as/asl.exe
P2BIN := wine ../../exec/as/p2bin.exe

MDSHELL_HEADLESS := ../../../build/mdshell/headless/MDShell.asm

TEST_BUILD_DIR := ../../../build/modules/errorhandler/tests

BUILD_DIR := ../../../build/modules/errorhandler


.PHONY:	all console-run console-utils flow-test raise-error linkable asm68k-dot-compat clean

all:	console-run console-utils flow-test raise-error linkable asm68k-dot-compat

clean:
	rm -f $(TEST_BUILD_DIR)/*


console-run:	| $(TEST_BUILD_DIR) $(MDSHELL_HEADLESS) $(CONVSYM)
	$(ASM68K) /k /m /o c+,ws+,op+,os+,ow+,oz+,oaq+,osq+,omq+,ae- /p /e __DEBUG__ console-run.asm, $(TEST_BUILD_DIR)/console-run.gen, $(TEST_BUILD_DIR)/console-run.sym, $(TEST_BUILD_DIR)/console-run.lst
	$(CONVSYM) $(TEST_BUILD_DIR)/console-run.sym $(TEST_BUILD_DIR)/console-run.gen -input asm68k_sym -output deb2 -a -ref 200

raise-error:	| $(TEST_BUILD_DIR) $(MDSHELL_HEADLESS) $(CONVSYM)
	$(ASM68K) /k /m /o c+,ws+,op+,os+,ow+,oz+,oaq+,osq+,omq+,ae- /p /e __DEBUG__ raise-error.asm, $(TEST_BUILD_DIR)/raise-error.gen, $(TEST_BUILD_DIR)/raise-error.sym, $(TEST_BUILD_DIR)/raise-error.lst
	$(CONVSYM) $(TEST_BUILD_DIR)/raise-error.sym $(TEST_BUILD_DIR)/raise-error.gen -input asm68k_sym -output deb2 -a -ref 200

linkable:	| $(TEST_BUILD_DIR) $(MDSHELL_HEADLESS) $(CONVSYM)
	$(ASM68K) /k /m /o c+,ws+,op+,os+,ow+,oz+,oaq+,osq+,omq+,ae- /g /l /e __DEBUG__ linkable.asm, $(TEST_BUILD_DIR)/linkable.obj, , $(TEST_BUILD_DIR)/linkable.lst
	$(PSYLINK) /p $(TEST_BUILD_DIR)/linkable.obj $(BUILD_DIR)/asm68k-linkable/Debugger.obj,$(TEST_BUILD_DIR)/linkable.gen,$(TEST_BUILD_DIR)/linkable.sym
	$(CONVSYM) $(TEST_BUILD_DIR)/linkable.sym $(TEST_BUILD_DIR)/linkable.gen -input asm68k_sym -output deb2 -a -ref 200

asm68k-dot-compat:	| $(TEST_BUILD_DIR) $(MDSHELL_HEADLESS) $(CONVSYM)
	$(ASM68K) /k /m /o c+,ws+,op+,os+,ow+,oz+,oaq+,osq+,omq+,ae-,v+ /g /l /e __DEBUG__ asm68k-dot-compat.asm, $(TEST_BUILD_DIR)/asm68k-dot-compat.obj, , $(TEST_BUILD_DIR)/asm68k-dot-compat.lst
	$(PSYLINK) /p $(TEST_BUILD_DIR)/asm68k-dot-compat.obj $(BUILD_DIR)/asm68k-linkable/Debugger.obj,$(TEST_BUILD_DIR)/asm68k-dot-compat.gen,$(TEST_BUILD_DIR)/asm68k-dot-compat.sym
	$(CONVSYM) $(TEST_BUILD_DIR)/asm68k-dot-compat.sym $(TEST_BUILD_DIR)/asm68k-dot-compat.gen -input asm68k_sym -output deb2 -inopt '/localSign=.' -a -ref 200

console-utils:	| $(TEST_BUILD_DIR) $(MDSHELL_HEADLESS) $(CONVSYM) $(CBUNDLE)
	$(CBUNDLE) console-utils.asm -def ASM68K -out $(TEST_BUILD_DIR)/console-utils-asm68k.asm
	$(CBUNDLE) console-utils.asm -def AS -out $(TEST_BUILD_DIR)/console-utils-as.asm

	$(ASM68K) /k /m /o c+,ws+,op+,os+,ow+,oz+,oaq+,osq+,omq+,ae- /p $(TEST_BUILD_DIR)/console-utils-asm68k.asm, $(TEST_BUILD_DIR)/console-utils-asm68k.gen, $(TEST_BUILD_DIR)/console-utils-asm68k.sym, $(TEST_BUILD_DIR)/console-utils-asm68k.lst
	$(CONVSYM) $(TEST_BUILD_DIR)/console-utils-asm68k.sym $(TEST_BUILD_DIR)/console-utils-asm68k.gen -in asm68k_sym -a -ref 200 -debug
	
	set AS_MSGPATH="..\..\exec\as"
	set USEANSI=n
	$(ASL) -U -xx -A -L -OLIST $(TEST_BUILD_DIR)/console-utils-as.lst $(TEST_BUILD_DIR)/console-utils-as.asm -o $(TEST_BUILD_DIR)/console-utils-as.p
	$(P2BIN) $(TEST_BUILD_DIR)/console-utils-as.p $(TEST_BUILD_DIR)/console-utils-as.gen -r 0x-0x
	rm $(TEST_BUILD_DIR)/console-utils-as.p
	$(CONVSYM) $(TEST_BUILD_DIR)/console-utils-as.lst $(TEST_BUILD_DIR)/console-utils-as.gen -in as_lst -a -ref 200

flow-test:	| $(TEST_BUILD_DIR) $(MDSHELL_HEADLESS) $(CONVSYM) $(CBUNDLE)
	$(CBUNDLE) flow-test.asm -def ASM68K -out $(TEST_BUILD_DIR)/flow-test-asm68k.asm
	$(CBUNDLE) flow-test.asm -def AS -out $(TEST_BUILD_DIR)/flow-test-as.asm

	$(ASM68K) /k /m /o c+ /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /p /o ae- $(TEST_BUILD_DIR)/flow-test-asm68k.asm, $(TEST_BUILD_DIR)/flow-test-asm68k.gen, $(TEST_BUILD_DIR)/flow-test-asm68k.sym, $(TEST_BUILD_DIR)/flow-test-asm68k.lst
	$(CONVSYM) $(TEST_BUILD_DIR)/flow-test-asm68k.sym $(TEST_BUILD_DIR)/flow-test-asm68k.gen -in asm68k_sym -a -ref 200 -debug
	
	set AS_MSGPATH="..\..\exec\as"
	set USEANSI=n
	$(ASL) -U -xx -A -L -OLIST $(TEST_BUILD_DIR)/flow-test-as.lst $(TEST_BUILD_DIR)/flow-test-as.asm -o $(TEST_BUILD_DIR)/flow-test-as.p
	$(P2BIN) $(TEST_BUILD_DIR)/flow-test-as.p $(TEST_BUILD_DIR)/flow-test-as.gen -r 0x-0x
	rm $(TEST_BUILD_DIR)/flow-test-as.p
	$(CONVSYM) $(TEST_BUILD_DIR)/flow-test-as.lst $(TEST_BUILD_DIR)/flow-test-as.gen -in as_lst -a -ref 200


$(MDSHELL_HEADLESS):
	$(MAKE) -C  ../../mdshell headless


$(TEST_BUILD_DIR):
	mkdir -p $(TEST_BUILD_DIR)
