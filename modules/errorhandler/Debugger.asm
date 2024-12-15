
; ===============================================================
; ---------------------------------------------------------------
; MD Debugger and Error Handler v.2.6
;
;
; Documentation, references and source code are available at:
; - https://github.com/vladikcomper/md-modules
;
; (c) 2016-2024, Vladikcomper
; ---------------------------------------------------------------
; Debugger definitions
; ---------------------------------------------------------------

#include Debugger.Config.asm


#include Debugger.Constants.asm

#ifdef LINKABLE
#ifdef BUNDLE-ASM68K
; ===============================================================
; ---------------------------------------------------------------
; Symbols imported from the object file
; ---------------------------------------------------------------

#include ../../build/modules/errorhandler-core/ErrorHandler.Linkable.Refs.asm
#else
## AS bundle doesn't support linkable builds!
#endif
#endif


; ===============================================================
; ---------------------------------------------------------------
; Macros
; ---------------------------------------------------------------

#ifdef BUNDLE-ASM68K
#include Debugger.Macros.ASM68K.asm
#endif
#ifdef BUNDLE-AXM68K
#include Debugger.Macros.ASM68K.asm
#endif
#ifdef BUNDLE-AS
#include Debugger.Macros.AS.asm
#endif
##

; ---------------------------------------------------------------
; MIT License
; 
; Copyright (c) 2016-2024 Vladikcomper
; 
; Permission is hereby granted, free of charge, to any person
; obtaining a copy ; of this software and associated
; documentation files (the "Software"), to deal in the Software 
; without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense,
; and/or sell copies of the Software, and to permit persons to
; whom the Software is furnished to do so, subject to the
; following conditions:
; 
; The above copyright notice and this permission notice shall be
; included in all copies or substantial portions of the Software.
; 
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
; OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
; OTHER DEALINGS IN THE SOFTWARE.
; ---------------------------------------------------------------
