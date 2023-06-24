
.PHONY:	all utils modules test clean

all:	utils modules

utils:
	$(MAKE) -C utils/convsym
	$(MAKE) -C utils/cbundle

modules:
	$(MAKE) -C modules/mdshell
	$(MAKE) -C modules/errorhandler

test:	all
	$(MAKE) -C utils/convsym test
	$(MAKE) -C utils/cbundle test
	$(MAKE) -C modules/mdshell tests
	$(MAKE) -C modules/errorhandler tests

clean:
	rm -drf build/modules build/utils
