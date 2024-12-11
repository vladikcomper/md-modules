
	.section .text
	.align 2

* ===============================================================
* ---------------------------------------------------------------
* MD Debugger and Error Handler v.2.6
*
* (c) 2016-2024, Vladikcomper
* ---------------------------------------------------------------
* Error handler blob (GNU AS version)
* ---------------------------------------------------------------

__ErrorHandler:
#include ../../build/modules/errorhandler-core/ErrorHandler.GAS.Blob.asm

* ---------------------------------------------------------------
* Exported symbols
* ---------------------------------------------------------------

#include ../../build/modules/errorhandler-core/ErrorHandler.GAS.Refs.asm

#include ../../build/modules/errorhandler-core/ErrorHandler.GAS.Globals.asm
