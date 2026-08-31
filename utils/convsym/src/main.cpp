
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.13									*
 * Main definitions file										*
 * (c) 2017-2026, Vladikcomper									*
 * ------------------------------------------------------------	*/

#include <cstdint>
#include <cstdio>
#include <exception>
#include <stdexcept>
#include <string>
#include <memory>
#include <functional>
#include <iostream>
#include <fstream>
#include <string_view>

#define PCRE2_CODE_UNIT_WIDTH 8
#include <pcre2.h>

#include <Logger.hpp>
#include <ArgvParser.hpp>

/* Input wrappers */
#include "Utils.hpp"
#include "input/ASM68K_Listing.cpp"
#include "input/ASM68K_Sym.cpp"
#include "input/AS_Listing.cpp"
#include "input/AS_Listing_Experimental.cpp"
#include "input/Log.cpp"
#include "input/TXT.cpp"

/* Output wrappers */
#include "output/DEB1.cpp"
#include "output/DEB2.cpp"
#include "output/Log.cpp"
#include "output/ASM.cpp"

#include "output/OutputWrapper.hpp"
#include "util/SymbolTable.hpp"


/* Main function */
int main (int argc, const char ** argv) {

	/* Provide help if no sufficient arguments were passed */
	if (argc < 3) {
		std::cout <<
			"ConvSym utility version 2.13\n"
			"(c) 2016-2026, vladikcomper\n"
			"\n"
			"Command line arguments:\n"
			"  convsym [input_file|-] [output_file|-] <options>\n"
			"\n"
			"Using \"-\" as a file name redirects I/O to stdin or stdout respectively.\n"
			"\n"
			"EXAMPLES:\n"
			"  convsym listing.lst symbols.log -input as_lst -output log\n"
			"  convsym listing.lst rom.bin -input as_lst -output deb2 -a\n"
			"\n"
			"OPTIONS:\n"
			"  -in [format]\n"
			"  -input [format]\n"
			"    Selects input file format.\n"
			"    Supported formats: asm68k_sym, as_lst, log, txt, asm68k_lst (deprecated), as_lst_exp (deprecated)\n"
			"    Default: asm68k_sym\n"
			"\n"
			"  -out [format]\n"
			"  -output [format]\n"
			"    Selects output file format. Supported formats: asm, deb2, deb1 (deprecated), log\n"
			"    Default: deb2\n"
			"\n"
			"  -inopt [options]\n"
			"    Additional options specific for the input format. See README for more information.\n"
			"    Default options (depending on -in [format]):\n"
			"      -in asm68k_sym -inopt \"/localSign=@ /localJoin=. /processLocals+ /ignoreConstants+\"\n"
			"      -in asm68k_lst -inopt \"/localSign=@ /localJoin=. /ignoreMacroDefs+ /ignoreMacroExp- /addMacrosAsOpcodes+ /processLocals+\"\n"
			"      -in as_lst -inopt \"/localJoin=. /processLocals+ /ignoreInternalSymbols+\"\n"
			"      -in log -inopt \"/separator=: /useDecimal-\"\n"
			"      -in txt -inopt \"/fmt='%%s %%X' /offsetFirst-\"\n"
			"\n"
			"  -outopt [options]\n"
			"    Additional options specific for the output format. See README for more information.\n"
			"    Default options (depending on -out [format]):\n"
			"      -out deb2 -outopt \"/favorLastLabels-\"\n"
			"      -out deb1 -outopt \"/favorLastLabels-\"\n"
			"      -out asm -outopt \"/fmt='%%s:	equ	$%%X'\"\n"
			"      -out log -outopt \"/fmt='%%X: %%s'\"\n"
			"\n"
			"Offsets conversion options:\n"
			"  -base [offset]\n"
			"    Sets the base offset for the input data: it is subtracted from every symbol's offset found in [input_file] to form the final offset.\n"
			"    Default: 0\n"
			"\n"
			"  -mask [offset]\n"
			"    Sets the mask for the offsets in the input data: it's applied to every offset found in [input_file] after the base offset subtraction (if occurs).\n"
			"    Default: FFFFFF\n"
			"\n"
			"  -range [bottom] [upper]\n"
			"    Determines the range for offsets allowed in a final symbol file (after subtraction of the base offset).\n"
			"    Default: 0 3FFFFF\n"
			"\n"
			"  -a\n"
			"    Enables \"Append mode\": symbol data is appended to the end of the [output_file]. Data overwrites file contents by default. This is usually used to append symbols to ROMs.\n"
			"\n"
			"  -noalign\n"
			"    Don't align symbol data in \"Append mode\", which is aligned to nearest even offset by default. Using this option is not recommended, it's only there to retain compatilibity with older ConvSym versions.\n"
			"\n"
			"Symbol table dump options:\n"
			"  -org [offset]\n"
			"  -org @[symbolName]\n"
			"    If set, symbol data will placed at the specified [offset] in the output file. This option cannot be used in \"append mode\".\n"
			"    You can specify @SomeSymbol instead of plain offset, in this case ConvSym will resolve that symbol's offset.\n"
			"\n"
			"  -ref [offset]\n"
			"  -ref @[symbolName]\n"
			"    If set, a 32-bit Big Endian offset pointing to the beginning of symbol data will be written at specified offset. This is can be used, if symbol data pointer must be written somewhere in the ROM header.\n"
			"    You can specify @SomeSymbol instead of plain offset, in this case ConvSym will resolve that symbol's offset.\n"
			"\n"
			"Symbols conversion and filtering options:\n"
			"  -toupper\n"
			"    Converts all symbol names to uppercase.\n"    
			"\n"
			"  -tolower\n"
			"    Converts all symbol names to lowercase.\n"
			"\n"
			"  -addprefix [string]\n"
			"    Prepends a specified prefix string to every symbol in the resulting table. Done after all other transformations.\n"
			"\n"
			"  -filter [regex]\n"
			"    Enables filtering of the symbol list fetched from the [input_file] based on a regular expression.\n"
			"\n"
			"  -exclude\n"
			"    If set, filter works in \"exclude mode\": all labels that DO match the -filter regex are removed from the list, everything else stays.\n"
		;
		return -1;
	}

	/* Default configuration */
	bool optAppend = false;								// enable or disable append mode
	bool optDebug = false;								// enable or disable debug output
	bool optFilterExclude = false;						// regex-based filter mode: include or exclude matched symbols
	bool optNoAlignOnAppend = false;					// when appending, don't align symbol table on even offsets
	bool optToUpper = false;
	bool optToLower = false;

	OffsetConversionOptions offsetConversionOptions{
		.baseOffset = 0,
		.offsetLeftBoundary = 0,
		.offsetRightBoundary = 0x3FFFFF,
		.offsetMask = 0xFFFFFF,
	};
	uint32_t appendOffset = 0;
	uint32_t pointerOffset = 0;

	std::string inputWrapperName = "asm68k_sym";		// default input format
	std::string outputWrapperName = "deb2";				// default output format
	std::string inputOpts = "";							// default options for input format
	std::string outputOpts = "";						// default options for output format
	std::string appendOffsetRaw = "";					// default append offset
	std::string pointerOffsetRaw = "";					// default pointer offset
	std::string filterRegexStr = "";					// default filter expression
	std::string prefixStr = "";							// default added prefix (empty)

	/* Parse command line arguments */
	const char *inputFileName = argv[1];
	const char *outputFileName = argv[2];
	{
		/* Decode parameters acording to list defined by "ParametersList" variable */
		try {
			ArgvParser::parse(argv+3, argc-3, {
				{ "-base", 		ArgvParser::Arg::hexNumber{ &offsetConversionOptions.baseOffset } },
				{ "-mask",		ArgvParser::Arg::hexNumber{ &offsetConversionOptions.offsetMask } },
				{ "-range",		ArgvParser::Arg::hexRange{ &offsetConversionOptions.offsetLeftBoundary,	&offsetConversionOptions.offsetRightBoundary } },
				{ "-a",			ArgvParser::Arg::flag{ &optAppend } },
				{ "-noalign",	ArgvParser::Arg::flag{ &optNoAlignOnAppend } },
				{ "-debug",		ArgvParser::Arg::flag{ &optDebug } },
				/* FIXME: "-quiet" option */
				{ "-in",		ArgvParser::Arg::string{ &inputWrapperName } },
				{ "-input",		ArgvParser::Arg::string{ &inputWrapperName } },
				{ "-inopt",		ArgvParser::Arg::string{ &inputOpts } },
				{ "-out",		ArgvParser::Arg::string{ &outputWrapperName } },
				{ "-output",	ArgvParser::Arg::string{ &outputWrapperName } },
				{ "-outopt",	ArgvParser::Arg::string{ &outputOpts } },
				{ "-org",		ArgvParser::Arg::string{ &appendOffsetRaw } },
				{ "-ref",		ArgvParser::Arg::string{ &pointerOffsetRaw } },
				{ "-filter",	ArgvParser::Arg::string{ &filterRegexStr } },
				{ "-exclude",	ArgvParser::Arg::flag{ &optFilterExclude } },
				{ "-addprefix",	ArgvParser::Arg::string{ &prefixStr } },
				{ "-toupper",	ArgvParser::Arg::flag{ &optToUpper } },
				{ "-tolower",	ArgvParser::Arg::flag{ &optToLower } }
			});
		}
		catch (const std::exception& err) {
			Logger::error(err.what());
			return -1;
		}
	}

	/* Apply configuration based off the parameters parsed ... */
	Logger::logLevel = optDebug ? Logger::Level::DEBUG : Logger::Level::WARN;
	if (optAppend == true) {
		if (!appendOffsetRaw.empty()) {
			Logger::warn("Using conflicting parameters: -a and -org. The -org parameter has no effect");
			appendOffsetRaw = "";
		}
		appendOffset = -1;
	}
	if (optFilterExclude && !filterRegexStr.length()) {
		Logger::warn("Using -exclude parameter without -filter [regex]. The -exclude parameter has no effect");
		optFilterExclude = false;
	}
	if (optToUpper && optToLower) {
		Logger::warn("Using conflicting parameters: -toupper and -tolower. The -toupper parameter has no effect");
		optToUpper = false;
	}

	/* Parse offsets specified by "-ref" and "-org" options, or request to resolve them from symbols later */
	SymbolToOffsetResolveTable symbolToOffsetResolveTable{};
	{
		const std::array<std::pair<std::string&, uint32_t&>, 2> offsetParameterBindings {
			std::make_pair(std::ref(pointerOffsetRaw), std::ref(pointerOffset)),	// "-ref" bindings
			std::make_pair(std::ref(appendOffsetRaw), std::ref((appendOffset)))		// "-org" bindings
		};
		for (const auto & [offsetStrRaw, offset] : offsetParameterBindings) {
			if (offsetStrRaw.empty()) {	// skip if parameter isn't defined
				continue;
			}
			if (offsetStrRaw[0] == '@') {	// e.g. "-ref @SymbolName"
				offset = -2;
				symbolToOffsetResolveTable.emplace(std::string_view(offsetStrRaw).substr(1), std::ref(offset));
			}
			else {	// e.g. "-ref 1234"
				try {
					offset = std::stoul(offsetStrRaw, 0, 16);
				}
				catch (std::invalid_argument const &) {
					Logger::error("Couldn't parse hex number in parameters: {}", offsetStrRaw);
					return -2;
				}
			}
		}
	}

	/* Retrieve symbols from the input file */
	SymbolTable symbolTable(offsetConversionOptions, symbolToOffsetResolveTable);
	try {
		std::unique_ptr<InputWrapper> inputWrapper;
		switch (Utils::hash(inputWrapperName)) {
			case Utils::hash("asm68k_sym"):		inputWrapper = std::make_unique<Input__ASM68K_Sym>(); break;
			case Utils::hash("as_lst"):			inputWrapper = std::make_unique<Input__AS_Listing>(); break;
			case Utils::hash("log"): 			inputWrapper = std::make_unique<Input__Log>(); break;
			case Utils::hash("txt"): 			inputWrapper = std::make_unique<Input__TXT>(); break;
			/* DEPRECATED parsers: */
			case Utils::hash("asm68k_lst"): 	inputWrapper = std::make_unique<Input__ASM68K_Listing>();
												Logger::warn("\"asm68k_lst\" input format is deprecated, use \"asm68k_sym\" instead" );	break;
			case Utils::hash("as_lst_exp"): 	inputWrapper = std::make_unique<Input__AS_Listing_Experimental>();
												Logger::warn("\"as_lst_exp\" input format is deprecated, use \"as_lst\" instead" );	break;
			default:
				throw std::runtime_error(std::format("Unknown input format specifier: {}", inputWrapperName));
		}

		std::ifstream fileStream;
		std::istream& inputStream = (std::string_view(inputFileName) == "-")
			? std::cin // "-" instead of a file name fallbacks to `stdin`
			: (fileStream.open(inputFileName, inputWrapper->preferredStreamMode), fileStream);
		if (inputStream.fail()) {
			throw std::runtime_error("Failed to open input file");
		}

		inputWrapper->parseOptions(inputOpts);
		inputWrapper->parse(symbolTable, inputStream);
	}
	catch (const std::exception& err) {
		Logger::error("Input parsing failed: {}", err.what());
		return -1;
	}

	/* Make sure all symbols referenced in options (e.g. "-ref", "-org"), if any, were resolved */
	for (const auto & [label, ptr] : symbolToOffsetResolveTable) {
		if (ptr.get() == (uint32_t)-2) {
			Logger::error("Couldn't resolve symbol \"{}\"", label);
			return -2;
		}
	}

	/* Sort symbol table by offset */
	symbolTable.sortByOffset();

	/* Apply transformation to symbols */
	if (optToUpper) {
		for (auto & [_, label] : symbolTable.data) {
			std::transform(label.begin(), label.end(), const_cast<char*>(label.begin()), ::toupper);
		}
		/* FIXME: This is a mistake */
		std::transform(filterRegexStr.begin(), filterRegexStr.end(), filterRegexStr.begin(), ::toupper);
	}
	if (optToLower) {
		for (auto & [_, label] : symbolTable.data) {
			std::transform(label.begin(), label.end(), const_cast<char*>(label.begin()), ::tolower);
		}
		std::transform(filterRegexStr.begin(), filterRegexStr.end(), filterRegexStr.begin(), ::tolower);
	}
	if (!prefixStr.empty()) {
		for (auto& [offset, label] : symbolTable.data) {
			label = symbolTable.arena.push_concat(prefixStr, label);
		}
	}
	
	/* Pre-filter symbols based on regular expression */
	if (filterRegexStr.length() > 0) {
		int pcre2ErrorCode = 0;
		std::size_t pcre2ErrorOffset = 0;
		pcre2_code* pcre2RegexCode = pcre2_compile(reinterpret_cast<PCRE2_SPTR8>(filterRegexStr.data()), filterRegexStr.size(), 0, &pcre2ErrorCode, &pcre2ErrorOffset, nullptr);
		if (!pcre2RegexCode) {
			PCRE2_UCHAR8 pcre2ErrorMessage[128];
			pcre2_get_error_message(pcre2ErrorCode, pcre2ErrorMessage, sizeof(pcre2ErrorMessage));
			throw std::runtime_error(std::format("Failed to compile filter regex at offset {}: {}", pcre2ErrorOffset, pcre2ErrorMessage));
		}

		pcre2_jit_compile(pcre2RegexCode, PCRE2_JIT_COMPLETE);

		pcre2_match_data* matchData = pcre2_match_data_create_from_pattern(pcre2RegexCode, nullptr);

		std::erase_if(symbolTable.data, [&](const SymbolTable::Record& symbol) {
			const int rc = pcre2_match(
				pcre2RegexCode,
				reinterpret_cast<PCRE2_SPTR8>(symbol.label.data()),
				symbol.label.length(),
				0,
				PCRE2_ANCHORED | PCRE2_ENDANCHORED,
				matchData, nullptr
			);
			return (rc >= 0) == optFilterExclude;
		});

		pcre2_match_data_free(matchData);
		pcre2_code_free(pcre2RegexCode);
	}

	/* Pass generated symbols list to the output wrapper */
	if (!symbolTable.data.empty()) {
		try {
			std::unique_ptr<OutputWrapper> outputWrapper;
			switch (Utils::hash(outputWrapperName)) {
				case Utils::hash("log"):	outputWrapper = std::make_unique<Output__Log>(); break;
				case Utils::hash("asm"):	outputWrapper = std::make_unique<Output__Asm>(); break;
				case Utils::hash("deb2"):	outputWrapper = std::make_unique<Output__Deb2>(); break;
				case Utils::hash("deb1"):	outputWrapper = std::make_unique<Output__Deb1>();
											Logger::warn("\"deb1\" output format is deprecated, use \"deb2\" instead" ); break;
				default:
					throw std::runtime_error(std::format("Unknown output format specifier: {}", outputWrapperName));
			}

			/* Setup output stream respecting various append flags */
			std::FILE* outputFile;
			if (std::string_view(outputFileName) == "-") {
				outputFile = stdout;
				/* FIXME: Fail in append mode */
			}
			else {
				if (appendOffset == 0) {
					outputFile = std::fopen(outputFileName, outputWrapper->preferredStreamMode == OutputWrapper::PreferredStreamMode::Text ? "w" : "wb");
				}
				else {
					outputFile = std::fopen(outputFileName, outputWrapper->preferredStreamMode == OutputWrapper::PreferredStreamMode::Text ? "r+" : "r+b");
					if (outputFile) {
						if (appendOffset == static_cast<uint32_t>(-1)) {
							std::fseek(outputFile, 0, SEEK_END);
							appendOffset = std::ftell(outputFile);
							if (!optNoAlignOnAppend && (appendOffset & 1) != 0) {
								Logger::debug("Auto-aligning append offset.");
								std::fputc(0x00, outputFile);
								appendOffset++;
							}
						}
						else {
							if (!optNoAlignOnAppend && ((appendOffset & 1) != 0)) {
								Logger::warn("An odd append offset is specified; the offset wasn't auto-aligned.");
							}
							std::fseek(outputFile, appendOffset, SEEK_SET);
						}
						if (pointerOffset != 0) {
							std::fseek(outputFile, pointerOffset, SEEK_SET);
							const uint32_t appendOffsetBE = Utils::asBigEndian<uint32_t>(appendOffset);
							std::fwrite((const char*)&appendOffsetBE, 4, 1, outputFile);
							std::fseek(outputFile, appendOffset, SEEK_SET);
						}
					}
				}
			}
			if (!outputFile) {
				throw std::runtime_error("Failed to open output file");
			}

			outputWrapper->parseOptions(outputOpts);
			outputWrapper->parse(symbolTable.data, outputFile);

			if (outputFile != stdout) std::fclose(outputFile);
		}
		catch (const std::exception& err) {
			Logger::error("Output generation failed: {}", err.what());
			return -2;
		}
	}
	else {
		Logger::error("No symbols passed for output, operation aborted");
		return -3;
	}

	return 0;
}
