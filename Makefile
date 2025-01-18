

.PHONY:	all utils modules test clean

ifeq ($(OS),Windows_NT)
MAKEFILE := Makefile.win
include utils\.Makefile.win # For $(CONVSYM), $(CBUNDLE)
else
MAKEFILE := Makefile
include utils/.Makefile # For $(CONVSYM), $(CBUNDLE)
endif

all:	utils modules

utils: $(CONVSYM) $(CBUNDLE)

modules:
	$(MAKE) -C modules/mdshell -f $(MAKEFILE)
	$(MAKE) -C modules/errorhandler -f $(MAKEFILE)

test:	all
	$(MAKE) -C utils/convsym test -f $(MAKEFILE)
	$(MAKE) -C utils/cbundle test -f $(MAKEFILE)
	$(MAKE) -C modules/mdshell tests -f $(MAKEFILE)
	$(MAKE) -C modules/errorhandler tests -f $(MAKEFILE)
	$(MAKE) -C modules/errorhandler-core tests -f $(MAKEFILE)

clean:
ifeq ($(OS),Windows_NT)
	-rd /q /s build\modules build\utils
else
	rm -drf build/modules build/utils
endif
