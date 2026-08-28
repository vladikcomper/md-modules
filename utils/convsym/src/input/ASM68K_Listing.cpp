
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.12									*
 * Input wrapper for the ASM68K listing format					*
 * ------------------------------------------------------------	*/

#include <cstddef>
#include <cstdint>
#include <iostream>
#include <fstream>
#include <string>
#include <string_view>
#include <unordered_set>

#include <IO.hpp>
#include <Utils.hpp>
#include <Logger.hpp>
#include <OptsParser.hpp>

#include "InputWrapper.hpp"


struct Input__ASM68K_Listing : public InputWrapper {

	Input__ASM68K_Listing() {}
	~Input__ASM68K_Listing() {}

	/** Supported options:
	  *	- `/localSign=x`			- determines character used to specify local labels
	  *	- `/localJoin=x`			- character used to join local label and its global "parent"
	  *	- `/ignoreMacroDefs?`		- specify if macro definitions listings should be ignored (lines between "macro" and "endm"); default: +
	  *	- `/ignoreMacroExp?`		- specify if lines representing macro expansions should be ignored; default: -
	  *	- `/addMacrosAsOpcodes?`	- set if macros that process label as parameter (defined as "macro *") should be recognized when used; default: +
	  *	- `/processLocals?`			- specify whether local labels will processed
	  */
	struct {
		char localSign;
		char localJoin;
		bool ignoreMacroDefs;
		bool ignoreMacroExp;
		bool addMacrosAsOpcodes;
		bool processLocals;
	} options = {
		.localSign = '@',
		.localJoin = '.',
		.ignoreMacroDefs = true,
		.ignoreMacroExp = false,
		.addMacrosAsOpcodes = true,
		.processLocals = true
	};

	void parseOptions(const std::string_view opts) {
		OptsParser::parse(opts, {
			{ "localSign",			OptsParser::Opt::Char{ &options.localSign } },
			{ "localJoin",			OptsParser::Opt::Char{ &options.localJoin } },
			{ "ignoreMacroDefs",	OptsParser::Opt::Bool{ &options.ignoreMacroDefs } },
			{ "ignoreMacroExp",		OptsParser::Opt::Bool{ &options.ignoreMacroExp } },
			{ "addMacrosAsOpcodes",	OptsParser::Opt::Bool{ &options.addMacrosAsOpcodes } },
			{ "processLocals",		OptsParser::Opt::Bool{ &options.processLocals } }
		});
	}

	void parse(SymbolTable& symbolTable, const char *fileName) {
		// Known issues:
		//	* Doesn't recognize line break character "&", as line continuations aren't properly listed by ASM68K

		// Variables
		std::string strLastGlobalLabel("");	// default global label name
		uint32_t lastSymbolOffset = -1;		// tracks symbols offsets to ignore sections where PC is reset (mainly Z80 stuff)

		// Setup buffer, symbols list and file for input
		std::ifstream fileStream;
		std::istream& input = (std::string_view(fileName) == "-") ? std::cin : (fileStream.open(fileName), fileStream);
		if (input.fail()) {
			throw std::runtime_error("Failed to open input file");
		}

		// Vocabulary for assembly directives that support labels
		// NOTICE: This will be also extended with macro names
		std::unordered_set<std::string> NamingOpcodes = {
			"=", "equ", "equs", "equr", "reg", "rs", "rsset", "set", "macro", "substr", "section", "group"
		};

		// Define re-usable conditions
		#define IS_HEX_CHAR(X) 			((unsigned)(X-'0')<10||(unsigned)(X-'A')<6)
		#define IS_START_OF_NAME(X)		((unsigned)(X-'A')<26||(unsigned)(X-'a')<26||(options.processLocals&&X==options.localSign)||X=='.'||X=='_')
		#define IS_NAME_CHAR(X)			((unsigned)(X-'A')<26||(unsigned)(X-'a')<26||(unsigned)(X-'0')<10||X=='?'||X=='.'||X=='_')
		#define IS_START_OF_LABEL(X)	((unsigned)(X-'A')<26||(unsigned)(X-'a')<26||(options.processLocals&&X==options.localSign)||X=='_')
		#define IS_LABEL_CHAR(X)		((unsigned)(X-'A')<26||(unsigned)(X-'a')<26||(unsigned)(X-'0')<10||X=='?'||X=='_')
		#define IS_WHITESPACE(X)		(X==' '||X=='\t')
		#define IS_ENDOFLINE(X)			(X=='\n'||X=='\r'||X==0x00)

		// For every string in a listing file ...
		std::string line;
		line.reserve(1024);
		std::size_t lineCounter = 0;
		while (Utils::getline_safe(input, line)) {
			lineCounter++;
			if (line.size() <= 36) continue;	// If line is too short, do not proceed

			uint8_t* const sBuffer = reinterpret_cast<uint8_t*>(line.data());
			uint8_t* const sLineOffset = sBuffer;		// E.g.: "00000AEE 301F <..>move.w (sp)+, d0\n"
			uint8_t* const sLineText = sBuffer+36;		// E.g.: "move.w (sp)+, d0\n"
			uint8_t* const cMacroMark = sBuffer+34;		// If contains "M" at the specified column (column 34), the line is macro expansion

			uint8_t* ptr = sBuffer;						// WARNING: Unsigned type is required here for certain range-based optimizations

			// Check for proper offset at the beginning of the listing line
			{
				bool hasProperOffset = true;
				for (int i = 0; i < 8; ++i) {
					if (!IS_HEX_CHAR(*ptr)) {
						hasProperOffset = false;
						break;
					}
					ptr++;
				}
				if (!hasProperOffset) {
					Logger::debug("Line {} doesn't have a proper offset, skipping...", lineCounter);
					continue;
				}
				*ptr++ = 0x00;					// separate offset, so "sLineOffset" is proper c-string, containing only offset
			}

			// If this line represents an expression result, ignore
			if (*ptr == '=') {
				continue;
			}
			
			// If this line is macro expansion and option is set to ignore expansions, ignore
			if (options.ignoreMacroExp && *cMacroMark == 'M') {
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
			if (IS_START_OF_NAME(*ptr)) {
				Logger::debug("Line {}: Possible label at the beginning of line", lineCounter);
				sLabel = ptr++;						// assume this as label
				while (IS_NAME_CHAR(*ptr)) ptr++;	// iterate through label characters

				// Make sure label ends properly
				if (IS_WHITESPACE(*ptr) || *ptr==':' || IS_ENDOFLINE(*ptr)) {
					*ptr++ = 0x00;			// mark labels end, so "sLabel" is a proper c-string containing label alone now
				}
				else {
					continue;				// cancel further processing
				}
			}

			// Scenario #2 : Line starts with idention (space or tab)
			// NOTICE: In this case, label cannot include certain characters allowed otherwise...
			else if (IS_WHITESPACE(*ptr)) {
				Logger::debug("Line {}: Possible label with idention", lineCounter);
				do { ptr++; } while (IS_WHITESPACE(*ptr)); 	// skip idention
				if (IS_START_OF_LABEL(*ptr)) {
					sLabel = ptr++;							// assume this as label
					while (IS_LABEL_CHAR(*ptr)) ptr++;		// iterate through label characters

					// Make sure label ends properly
					if (*ptr==':') {
						*ptr++ = 0x00;			// mark labels end, so "sLabel" is a proper c-string containing label alone now
					}
					else {
						continue;				// cancel further processing
					}
				}
			}

			// Scenario #3: Line doesn't seem to contain a label ...
			else {
				Logger::debug("Line {}: Didn't identify label, skipping", lineCounter);
				continue;
			}

			// If label was determined ...
			// WARNING: "ptr" should point past label's end!
			if (sLabel != nullptr) {
				// Construct full label's name as std::string object
				std::string strLabel;
				if (*sLabel == options.localSign) {
					strLabel  = strLastGlobalLabel;
					strLabel += options.localJoin;
					strLabel += (char*)sLabel+1;	// +1 to skip local label symbol itself
				}
				else {
					strLabel = strLastGlobalLabel = (char*)sLabel;
				}

				// Fetch label's opcode into std::string object
				while (IS_WHITESPACE(*ptr)) ptr++; 		// skip indention
				uint8_t* const ptr_start = ptr;
				do { ptr++; } while (!IS_WHITESPACE(*ptr) && !IS_ENDOFLINE(*ptr));
				*ptr++ = 0x00;
				std::string strOpcode((char*)ptr_start, ptr-ptr_start-1);		// construct opcode string
				if (strOpcode[0] == options.localSign) {					// in case opcode is a local label reference
					strOpcode = strLastGlobalLabel;
					strOpcode += options.localJoin;
					strOpcode += (char*)ptr_start+1;	// +1 to skip local label symbol itself
				}

				Logger::debug("Processing: {}: {}", strLabel, strOpcode);

				// Make sure this label doesn't name any special object ...
				auto opcodeRef = NamingOpcodes.find(strOpcode);
				if (opcodeRef != NamingOpcodes.end()) {
					// If this label names a macro ...
					if (!opcodeRef->compare("macro")) {	// TODOh: Optimize by handling pointer to "macro" record within set

						Logger::debug("{} recognized as macro declaration", strLabel);

						// If macro processing option is on ...
						if (options.addMacrosAsOpcodes) {
							while (IS_WHITESPACE(*ptr)) ptr++; 	// skip indention

							// If macro uses labels as argument, add macro's name (the label) to the vocabulary
							if (*ptr == '*') {
								NamingOpcodes.insert(strLabel);
							}
						}

						// If ignore macro definitions option is on ...
						if (options.ignoreMacroDefs) {
							bool endmDirectiveReached = false;

							std::size_t macroLineCounter = 0;
							while (Utils::getline_safe(input, line)) {
								// Maintain line counter to warn if suspiciously many lines were processed as macro definition alone
								macroLineCounter++;
								if (macroLineCounter >= 1000) {
									Logger::warn(
										// TODOh: Advise to enable ignore macro definitions option?
										"Too many lines (>=1000) found in definition of \"{}\" macro. This could be missing \"endm\" statement or a parsing error.",
										strLabel
									);
									break;
								}

								if (line.size() <= 36) continue;	// Make sure this line includes assembly text

								ptr = reinterpret_cast<uint8_t*>(line.data()) + 36;

								// If line starts with label, skip it ...
								if (!IS_WHITESPACE(*ptr)) {
									do { ptr++; } while (!IS_WHITESPACE(*ptr) && !IS_ENDOFLINE(*ptr));
								}
								
								// Fetch opcode, if present ...
								while (IS_WHITESPACE(*ptr)) ptr++;
								uint8_t* const ptr_start = ptr;
								do { ptr++; } while (!IS_WHITESPACE(*ptr) && !IS_ENDOFLINE(*ptr));
								*ptr++ = 0x00;
								
								// If opcode is "endm", stop processing
								if (!strcmp((char*)ptr_start, "endm")) {
									Logger::debug(
										"Skipped definition of macro \"{}\" (lines {}-{})",
										strLabel, lineCounter, lineCounter+macroLineCounter
									);
									lineCounter += macroLineCounter;
									endmDirectiveReached = true;
									break;
								}
							}
							
							// If end of file was reached before "endm"
							if (!endmDirectiveReached) {
								Logger::error(
									// TODOh: Advise to enable ignore macro definitions option?
									"Couldn't reach end of \"{}\" macro. This is possibly due to a parsing error.",
									strLabel
								);
								break;
							}

							// Otherwise, cancel further processing
							else {
								continue;
							}
						}
					}

					Logger::debug("{} recognized as macro symbol", strLabel);
					continue;				// cancel further processing
				}

				// Decode symbol offset
				uint32_t offset = 0;
				for (uint8_t* c = sLineOffset; *c; c++) {
					offset = offset*0x10 + (((unsigned)(*c-'0')<10) ? (*c-'0') : (*c-('A'-10)));
				}

				// Add label to the symbols table, if:
				//	1) Its absolute offset is higher than the previous offset successfully added
				//	2) When base offset is subtracted and the mask is applied, the resulting offset is within allowed boundaries
				if ((lastSymbolOffset == (uint32_t)-1) || (offset >= lastSymbolOffset)) {
					const bool inserted = symbolTable.add(offset, strLabel);
					if (inserted) {
						lastSymbolOffset = offset;
					}
				}
				else {
					Logger::debug("Symbol {} at offset {:X} ignored: its offset is less than the previous symbol successfully fetched", strLabel, offset);
				}
			}
		}

		// Undefine conditions, so they can be redefined in other format handlers
		#undef IS_HEX_CHAR
		#undef IS_START_OF_NAME
		#undef IS_NAME_CHAR
		#undef IS_START_OF_LABEL
		#undef IS_LABEL_CHAR
		#undef IS_WHITESPACE
		#undef IS_ENDOFLINE
	}
};
