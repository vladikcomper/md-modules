############################
## CBundle testing script ##
############################

This raw line should be skipped as not part of any file...

#file output-1.txt
This file contains only raw strings ...
... and no directives.
#endf

## Define some symbols ...
#define TestSymbol

#file output-2.txt
#include common-include.txt
#ifdef TestSymbol2
	This text AND the following block should have no effect...
	#ifdef 1
	#else
	#endif
	... still no effect.
#else
	TestSymbol2 wasn't defined (reported by #ifdef > #else)
#endif
## The following command should have no effect:
#undef TestSymbol2
#ifndef TestSymbol2
	TestSymbol2 wasn't defined (reported by #ifndef)
#endif
#define Test
#ifdef Test
	Test was defined!
#endif
#undef Test
#ifndef Test
	Test wasn't defined
#endif
#endf
