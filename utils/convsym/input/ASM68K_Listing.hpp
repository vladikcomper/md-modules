
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.0									*
 * Input wrapper for the ASM68K listing format					*
 * ------------------------------------------------------------	*/


struct Input__ASM68K_Listing : public InputWrapper {


	Input__ASM68K_Listing() : InputWrapper() { // Constructor

	}

	~Input__ASM68K_Listing() {	// Destructor

	}

	/**
	 * Interface for input file parsing
	 * @param path Input file path
	 * @param baseOffset Base offset for the parsed records (subtracted from the fetched offsets to produce internal offsets)
	 * @param offsetLeftBoundary Left boundary for the calculated offsets
	 * @param offsetRightBoundary Right boundary for the calculated offsets
	 * @return Sorted associative array (map) of found offsets and their corresponding symbol names
	 */
	map<uint32_t, string>
	parse(	const char *fileName,
			uint32_t baseOffset = 0x000000,
			uint32_t offsetLeftBoundary = 0x000000,
			uint32_t offsetRightBoundary = 0x3FFFFF,
			const char * opts = "" ) {

		// Known issues:
		//	* Doesn't recognize line break character "&", as line continuations aren't properly listed by ASM68K

		// Supported options:
		//	/localSign=x			- determines character used to specify local labels
		//	/localJoin=x			- character used to join local label and its global "parent"
		//	/ignoreMacroDefs?		- specify if macro definitions listings should be ignored (lines between "macro" and "endm"); default: +
		//	/ignoreMacroExp?		- specify if lines representing macro expansions should be ignored; default: -
		//	/addMacrosAsOpcodes?	- set if macros that process label as parameter (defined as "macro *") should be recognized when used; default: +

		// Default processing options
		bool optIgnoreMacroExpansions = false;
		bool optIgnoreMacroDefinitions = true;
		bool optRegisterMacrosAsOpcodes = true;
		bool optProcessLocalLabels = true;

		// Variables
		long lineCounter = 0;
		string strLastGlobalLabel("");		// default global label name
		char localLabelSymbol = '@';		// default symbol for local labels
		char localLabelRef = '.';			// default symbol to reference local labels within global ones
		int32_t lastSymbolOffset = -1;		// tracks symbols offsets to ignore sections where PC is reset (mainly Z80 stuff)

		// Fetch options from "-inopt" agrument's value
		const map<string, OptsParser::record>
			OptsList {
				{ "localSign",			{ type: OptsParser::record::p_char,		target:	&localLabelSymbol			} },
				{ "localJoin",			{ type: OptsParser::record::p_char,		target:	&localLabelRef				} },
				{ "ignoreMacroDefs",	{ type: OptsParser::record::p_bool,		target:	&optIgnoreMacroDefinitions	} },
				{ "ignoreMacroExp",		{ type: OptsParser::record::p_bool,		target:	&optIgnoreMacroExpansions	} },
				{ "addMacrosAsOpcodes",	{ type: OptsParser::record::p_bool,		target:	&optRegisterMacrosAsOpcodes	} },
				{ "processLocals",		{ type: OptsParser::record::p_bool,		target:	&optProcessLocalLabels		} }
			};
			
		OptsParser::parse( opts, OptsList );

		// Setup buffer, symbols list and file for input
		const int sBufferSize = 1024;
		uint8_t sBuffer[ sBufferSize ];
		map<uint32_t, string> SymbolMap;
		IO::FileInput input = IO::FileInput( fileName, IO::text );
		if ( !input.good() ) { throw "Couldn't open input file"; }


		// Vocabulary for assembly directives that support labels
		// NOTICE: This will be also extended with macro names
		set<string> NamingOpcodes = {
			"=", "equ", "equs", "equr", "reg", "rs", "rsset", "set", "macro", "substr", "section", "group"
		};

		// Define re-usable conditions
		#define IS_HEX_CHAR(X) 			((unsigned)(X-'0')<10||(unsigned)(X-'A')<6)
		#define IS_START_OF_NAME(X)		((unsigned)(X-'A')<26||(unsigned)(X-'a')<26||(optProcessLocalLabels&&X==localLabelSymbol)||X=='.'||X=='_')
		#define IS_NAME_CHAR(X)			((unsigned)(X-'A')<26||(unsigned)(X-'a')<26||(unsigned)(X-'0')<10||X=='?'||X=='.'||X=='_')
		#define IS_START_OF_LABEL(X)	((unsigned)(X-'A')<26||(unsigned)(X-'a')<26||(optProcessLocalLabels&&X==localLabelSymbol)||X=='_')
		#define IS_LABEL_CHAR(X)		((unsigned)(X-'A')<26||(unsigned)(X-'a')<26||(unsigned)(X-'0')<10||X=='?'||X=='_')
		#define IS_INDENTION(X)			(X==' '||X=='\t')


		// For every string in a listing file ...
		while ( input.readString( sBuffer, sBufferSize ) ) {

        	lineCounter++;

			uint8_t* const sLineOffset = sBuffer;		// E.g.: "00000AEE 301F <..>move.w (sp)+, d0\n"
			uint8_t* const sLineText = sBuffer+36;		// E.g.: "move.w (sp)+, d0\n"
			uint8_t* const cMacroMark = sBuffer+34;		// If contains "M" at the specified column (column 34), the line is macro expansion

			uint8_t* ptr = sBuffer;						// WARNING: Unsigned type is required here for certain range-based optimizations

			// Read line offset
			if ( !IS_HEX_CHAR(*ptr) ) { continue; }	ptr++;	// check digit #0 of offset
			if ( !IS_HEX_CHAR(*ptr) ) { continue; }	ptr++;	// check digit #1 of offset
			if ( !IS_HEX_CHAR(*ptr) ) { continue; }	ptr++;	// check digit #2 of offset
			if ( !IS_HEX_CHAR(*ptr) ) { continue; }	ptr++;	// check digit #3 of offset
			if ( !IS_HEX_CHAR(*ptr) ) { continue; }	ptr++;	// check digit #4 of offset
			if ( !IS_HEX_CHAR(*ptr) ) { continue; }	ptr++;	// check digit #5 of offset
			if ( !IS_HEX_CHAR(*ptr) ) { continue; }	ptr++;	// check digit #6 of offset
			if ( !IS_HEX_CHAR(*ptr) ) { continue; }	ptr++;	// check digit #7 of offset
			*ptr++ = 0x00;								// separate offset, so "sLineOffset" is proper c-string, containing only offset


			// If this line represents an expression result, ignore
			if ( *ptr == '=' ) {
				continue;
			}
			
			// If this line is macro expansion and option is set to ignore expansions, ignore
			if ( optIgnoreMacroExpansions && *cMacroMark == 'M' ) {
				continue;
			}

			// NOTICE: If line offset is present, it's guranteed that line is at least 36 characters long, so ...
			// ... "sLineText = sBuffer+36" is a valid location
			uint8_t* sLabel = nullptr;			// assume label is NULL, but the following blocks of code will attempt to find lable in the line
			ptr = sLineText;

			// -----------------------------------------------------------
			// Code to intentify if label or name is present on the line
			// -----------------------------------------------------------

			// Scenario #1 : Line doesn't have indention, meaning it starts with a name
			// NOTICE: In this case, label may use a wider range of allowed characters, hence it's referenced as "NAME" below ...
			if ( IS_START_OF_NAME(*ptr) ) {
				sLabel = ptr++;					// assume this as label
				while ( IS_NAME_CHAR(*ptr) ) ptr++;	// iterate through label characters

				// Make sure label ends properly
				if ( IS_INDENTION(*ptr) || *ptr==':' || *ptr=='\n' ) {
					*ptr++ = 0x00;			// mark labels end, so "sLabel" is a proper c-string containing label alone now
				}
				else {
					continue;				// cancel further processing
				}
			}

			// Scenario #2 : Line starts with idention (space or tab)
			// NOTICE: In this case, label cannot include certain characters allowed otherwise...
			else if ( IS_INDENTION(*ptr) ) {
				do { ptr++; } while ( IS_INDENTION(*ptr) ); 	// skip idention
				if ( IS_START_OF_LABEL(*ptr) ) {
					sLabel = ptr++;						// assume this as label
					while ( IS_LABEL_CHAR(*ptr) ) ptr++;	// iterate through label characters

					// Make sure label ends properly
					if ( *ptr==':' ) {
						*ptr++ = 0x00;			// mark labels end, so "sLabel" is a proper c-string containing label alone now
					}
					else {
						continue;				// cancel further processing
					}
				}
			}

			// If label was determined ...
			// WARNING: "ptr" should point past label's end!
			if ( sLabel != nullptr ) {

				// Construct full label's name as std::string object
				bool labelIsLocal;
				string strLabel;
				if ( *sLabel == localLabelSymbol ) {
					labelIsLocal = true;
					strLabel  = strLastGlobalLabel;
					strLabel += localLabelRef;
					strLabel += (char*)sLabel+1;	// +1 to skip local label symbol itself
				}
				else {
					labelIsLocal = false;
					strLabel = (char*)sLabel;
					//strLastGlobalLabel = strLabel;	// NOTICE: This logic has moved down to insert label sequence,
														//	as we do not know yet if this label fits ...
				}

				// Fetch label's opcode into std::string object
				while ( IS_INDENTION(*ptr) ) ptr++; 	// skip indention
            	uint8_t* const ptr_start = ptr;
				do { ptr++; } while ( !IS_INDENTION(*ptr) && *ptr!='\n' );
				*ptr++ = 0x00;
				string strOpcode( (char*)ptr_start, ptr-ptr_start-1 );		// construct opcode string
				if ( strOpcode[0] == localLabelSymbol ) {					// in case opcode is a local label reference
					strOpcode = strLastGlobalLabel;
					strOpcode += localLabelRef;
					strOpcode += (char*)ptr_start+1;	// +1 to skip local label symbol itself
				}
				
				IO::Log( IO::debug, "Processing: %s: %s", strLabel.c_str(), strOpcode.c_str() );

				// Make sure this label doesn't name any special object ...
				auto opcodeRef = NamingOpcodes.find( strOpcode );
				if ( opcodeRef != NamingOpcodes.end() ) {
					// If this label names a macro ...
					if ( !opcodeRef->compare("macro") ) {	// TODOh: Optimize by handling pointer to "macro" record within set

						IO::Log( IO::debug, "%s recognized as macro declaration", strLabel.c_str() );

						// If macro processing option is on ...
						if ( optRegisterMacrosAsOpcodes ) {
							while ( IS_INDENTION(*ptr) ) ptr++; 	// skip indention

							// If macro uses labels as argument, add macro's name (the label) to the vocabulary
							if ( *ptr == '*' ) {
								NamingOpcodes.insert( strLabel );
							}
						}

						// If ignore macro definitions option is on ...
						if ( optIgnoreMacroDefinitions ) {

							int macroLineCounter = 0;
							bool IOsuccessful;
							while ( (IOsuccessful = input.readString( sBuffer, sBufferSize )) ) {

        						macroLineCounter++;

								// Maintain line counter to warn if suspiciously many lines were processed as macro definition alone
								if ( macroLineCounter == 1000 ) {
									IO::Log( IO::warning,
										// TODOh: Advise to enable ignore macro definitions option?
										"Too many lines found in definition of \"%s\" macro. This is possibly due to a parsing error.",
										strLabel.c_str()
									);
								}

								ptr = sBuffer;

								// Make sure this line includes assembly text
								while ( *ptr && (ptr-sBuffer)<36 ) { ptr++; }
								if ( (ptr-sBuffer)<36 ) continue;

								// If line starts with label, skip it ...
								if ( !IS_INDENTION(*ptr) ) {
									do { ptr++; } while ( !IS_INDENTION(*ptr) && *ptr!='\n' && *ptr );
								}
								
								// Fetch opcode, if present ...
								while ( IS_INDENTION(*ptr) ) ptr++;
				            	uint8_t* const ptr_start = ptr;
								do { ptr++; } while ( !IS_INDENTION(*ptr) && *ptr!='\n' );
								*ptr++ = 0x00;
								
								// If opcode is "endm", stop processing
								if ( !strcmp( (char*)ptr_start, "endm" ) ) {
									IO::Log( IO::debug,
										"Skipped definition of macro \"%s\" (lines %d-%d)",
										strLabel.c_str(), lineCounter, lineCounter+macroLineCounter
									);
									lineCounter += macroLineCounter;
									break;
								}

							}
							
							// If end of file was reached before "endm"
							if ( !IOsuccessful ) {
								IO::Log( IO::error,
									// TODOh: Advise to enable ignore macro definitions option?
									"Couldn't reach end of \"%s\" macro. This is possibly due to a parsing error.",
									strLabel.c_str()
								);
							}

							continue;				// cancel further processing
						}
					}

					IO::Log( IO::debug, "%s recognized as macro symbol", strLabel.c_str() );
					continue;				// cancel further processing

				}

				// Decode symbol offset
				uint32_t offset = 0;
				for ( uint8_t* c = sLineOffset; *c; c++ ) {
					offset = offset*0x10 + (((unsigned)(*c-'0')<10) ? (*c-'0') : (*c-('A'-10)));
				}

				if ( (signed)offset > lastSymbolOffset ) {
					lastSymbolOffset = offset;

					// Add label to the symbols table
					offset -= baseOffset;
					if ( offset >= offsetLeftBoundary && offset <= offsetRightBoundary ) {	// if offset is within range, add it ...
						IO::Log( IO::debug, "Adding %s as label...", strLabel.c_str() );
			            SymbolMap.insert( { offset, strLabel } );             
						if (!labelIsLocal) {
							strLastGlobalLabel = strLabel;
						}
					}
				}
				else {
					IO::Log( IO::debug, "Symbol %s at offset %X ignored: its offset is less than the previous symbol successfully fetched", strLabel.c_str(), offset );
				}

			}

		}

		// Undefine conditions, so they can be redefined in other format handlers
		#undef IS_HEX_CHAR
		#undef IS_START_OF_NAME
		#undef IS_NAME_CHAR
		#undef IS_START_OF_LABEL
		#undef IS_LABEL_CHAR
		#undef IS_INDENTION

		return SymbolMap;

	}

};
