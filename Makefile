
.PHONY:	all utils modules clean

all:	utils modules

utils:
	$(MAKE) -C utils/convsym
	$(MAKE) -C utils/cbundle

modules:
	$(MAKE) -C modules/mdshell
	$(MAKE) -C modules/errorhandler

clean:
	rm -drf build/modules build/utils
