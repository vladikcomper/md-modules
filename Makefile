
.PHONY:	all utils modules clean

all:	utils modules

utils:
	make -C utils/convsym
	make -C utils/cbundle

modules:
	make -C modules/mdshell
	make -C modules/errorhandler

clean:
	rm -drf build/modules build/utils
