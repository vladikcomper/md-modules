
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.14									*
 * Main definitions file										*
 * (c) 2017-2026, Vladikcomper									*
 * ------------------------------------------------------------	*/

#include <cstdint>
#include <cstdio>
#include <exception>
#include <optional>
#include <stdexcept>
#include <memory>
#include <iostream>
#include <fstream>
#include <string_view>
#include <variant>

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

#define CONVSYM_VERSION_LINE "ConvSym utility version 2.14\n"
#define CONVSYM_COPYRIGHT_LINE "(c) 2016-2026, Vladikcomper\n"

/* Main function */
int main (int argc, const char ** argv) {

	/* Provide help if no sufficient arguments were passed */
	if (argc < 3) {
		std::fputs(
			CONVSYM_VERSION_LINE
			CONVSYM_COPYRIGHT_LINE
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
			"\n"
			"  -verbose\n"
			"    Enables more verbose output (useful for troubleshooting).\n"
			"\n"
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
			"  -range [start] [end]\n"
			"  -range @[startSymbol] @[endSymbol]\n"
			"    Determines the range for offsets allowed in a final symbol file (after subtraction of the base offset).\n"
			"    You can specify something like \"-range @MyStartSymbol @MyEndSymbol\" instead of raw offsets, so ConvSym will limit output to anything between their offsets automatically.\n"
			"    Default: 0 FFFFFFFF (all addressable space)\n"
			"\n"
			"  -a\n"
			"    Enables \"Append mode\": symbol data is appended to the end of the [output_file]. Data overwrites file contents by default. This is usually used to append symbols to ROMs.\n"
			"\n"
			"  -noalign\n"
			"    Don't align symbol data in \"Append mode\", which is aligned to nearest even offset by default. Using this option is not recommended, it's only there to retain compatibility with older ConvSym versions.\n"
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
			"  -filter [regex]\n"
			"  -ifilter [regex]\n"
			"    Enables filtering of the symbol list fetched from the [input_file] based on a regular expression.\n"
			"    Filtering is done before any other transformations (see below). For case-insensitive regex, use \"-ifilter\" instead.\n"
			"\n"
			"  -exclude\n"
			"    Make filter work in \"exclude mode\": all labels that DO match the filter regex are removed from the list, everything else stays.\n"
			"\n"
			"  -toupper\n"
			"    Converts all symbol names to uppercase.\n"    
			"\n"
			"  -tolower\n"
			"    Converts all symbol names to lowercase.\n"
			"\n"
			"  -rmprefix [string]\n"
			"    Removes a specified prefix if symbol starts with it. Done after all other transformations, but before -addprefix.\n"
			"\n"
			"  -addprefix [string]\n"
			"    Prepends a specified prefix string to every symbol in the resulting table. Done after all other transformations.\n",
			stderr
		);
		return -1;
	}


	/* ----------------------------------- */
	/* PHASE 1: Parse command-line options */
	/* ----------------------------------- */

	Logger::logLevel = Logger::Level::WARN;
	enum class CharacterTransformMode { None, ToUpper, ToLower };
	struct FilterRegex { std::string_view expression; bool caseInsensitive; };
	struct Args {
		const char* 					input_file;
		const char* 					output_file;
		std::string_view 				input_format;
		std::string_view 				output_format;
		std::string_view 				input_options;
		std::string_view 				output_options;
		bool 							output_append_end;
		bool 							output_append_no_align;
		std::optional<offset_or_symbol> output_append_offset;
		std::optional<offset_or_symbol> output_append_ref_offset;
		FilterRegex 					filter_regex;
		bool 							filter_exclude_matching;
		std::string_view				add_prefix;
		std::string_view				remove_prefix;
		CharacterTransformMode 			character_transform;
		uint32_t 						offset_base;
		offset_or_symbol				offset_low_boundary;
		offset_or_symbol				offset_high_boundary;
		uint32_t						offset_mask;
	} args {
		/* Input/output options */
		.input_file = argv[1],
		.output_file = argv[2],
		.input_format = "asm68k_sym",
		.output_format = "deb2",
		.input_options = "",
		.output_options = "",
		.output_append_end = false,
		.output_append_no_align = false,
		.output_append_offset = std::nullopt,
		.output_append_ref_offset = std::nullopt,

		/* Filter and offset transform options */
		.filter_regex = { .expression = "", .caseInsensitive = false },
		.filter_exclude_matching = false,
		.add_prefix = "",
		.remove_prefix = "",
		.character_transform = CharacterTransformMode::None,
		.offset_base = (uint32_t)0,
		.offset_low_boundary = (uint32_t)0,
		.offset_high_boundary = (uint32_t)0xFFFFFFFF,
		.offset_mask = (uint32_t)0xFFFFFF
	};
	{
		try {
			using namespace ArgvParser;
			constexpr auto offsetOrSymbolGetter = [](std::string_view value) -> std::variant<uint32_t, std::string_view> {
				assert(!value.empty());
				if (value[0] == '@') return value.substr(1);	// @[symbol] format
				return static_cast<uint32_t>(Getter::hexNumber(value));	// otherwise, assume a number
			};
			constexpr auto filterRegexGetter = [](std::string_view value) -> FilterRegex {
				return { .expression = value, .caseInsensitive = false };
			};
			constexpr auto ifilterRegexGetter = [](std::string_view value) -> FilterRegex {
				return { .expression = value, .caseInsensitive = true };
			};

			parse(argv+3, argc-3, {
				{ "-base", 		Arg<uint32_t, Getter::hexNumber>{ &args.offset_base } },
				{ "-mask",		Arg<uint32_t, Getter::hexNumber>{ &args.offset_mask } },
				{ "-range",		RangeArg<offset_or_symbol, offsetOrSymbolGetter>{ &args.offset_low_boundary, &args.offset_high_boundary } },
				{ "-a",			Switch{ &args.output_append_end } },
				{ "-noalign",	Switch{ &args.output_append_no_align } },
				{ "-debug",		Switch<Logger::Level, Logger::Level::DEBUG>{ &Logger::logLevel } },
				{ "-verbose",	Switch<Logger::Level, Logger::Level::INFO>{ &Logger::logLevel } },
				{ "-in",		Arg{ &args.input_format } },
				{ "-input",		Arg{ &args.input_format } },
				{ "-inopt",		Arg{ &args.input_options } },
				{ "-out",		Arg{ &args.output_format } },
				{ "-output",	Arg{ &args.output_format } },
				{ "-outopt",	Arg{ &args.output_options } },
				{ "-org",		Arg<std::optional<offset_or_symbol>, offsetOrSymbolGetter>{ &args.output_append_offset } },
				{ "-ref",		Arg<std::optional<offset_or_symbol>, offsetOrSymbolGetter>{ &args.output_append_ref_offset } },
				{ "-filter",	Arg<FilterRegex, filterRegexGetter>{ &args.filter_regex } },
				{ "-ifilter",	Arg<FilterRegex, ifilterRegexGetter>{ &args.filter_regex } },
				{ "-exclude",	Switch{ &args.filter_exclude_matching } },
				{ "-addprefix",	Arg{ &args.add_prefix } },
				{ "-rmprefix",	Arg{ &args.remove_prefix } },
				{ "-toupper",	Switch<CharacterTransformMode, CharacterTransformMode::ToUpper>{ &args.character_transform } },
				{ "-tolower",	Switch<CharacterTransformMode, CharacterTransformMode::ToLower>{ &args.character_transform } },
			});

			/* Additional arguments sanity checks */
			if (args.output_append_end && args.output_append_offset.has_value()) {
				throw std::runtime_error("Conflicting options: \"-a\" (append end) and \"-org [offset]\" (append at [offset])");
			}
			if (args.filter_exclude_matching && args.filter_regex.expression.empty()) {
				throw std::runtime_error("Conflicting options: \"-exclude\" option can only be used with \"-filter [regex]\"");
			}
			if (args.output_append_ref_offset.has_value() && !(args.output_append_end || args.output_append_offset.has_value())) {
				throw std::runtime_error("\"-ref\" option only works in \"append mode\": must be used with \"-a\" or \"-org\"");
			}
		}
		catch (const std::exception& err) {
			Logger::error("Invalid arguments: {}", err.what());
			return -1;
		}
	}

	/* For verbose output, display version and performed operations */
	Logger::info(CONVSYM_VERSION_LINE CONVSYM_COPYRIGHT_LINE);

	OffsetConversionOptions offsetConversionOpts {
		.baseOffset = args.offset_base,
		.offsetMask = args.offset_mask,
		/* If offset boundaries are passed as symbols and require resolution, default to 0-$FFFFFFFF range */
		.offsetLowBoundary = std::holds_alternative<uint32_t>(args.offset_low_boundary) ? std::get<uint32_t>(args.offset_low_boundary) : 0,
		.offsetHighBoundary = std::holds_alternative<uint32_t>(args.offset_high_boundary) ? std::get<uint32_t>(args.offset_high_boundary) : 0xFFFFFFFF
	};

	/* If any of symbol-based refs used in `-org`, `-ref` and `-range` options, store references to resolve after input pass */
	std::vector<SymbolRef> symbolRefTable;
	symbolRefTable.reserve(4);	// currently, this table may hold up to 4 references at most
	{
		if (std::holds_alternative<std::string_view>(args.offset_low_boundary)) {
			symbolRefTable.emplace_back(std::get<std::string_view>(args.offset_low_boundary), &args.offset_low_boundary);
		}
		if (std::holds_alternative<std::string_view>(args.offset_high_boundary)) {
			symbolRefTable.emplace_back(std::get<std::string_view>(args.offset_high_boundary), &args.offset_high_boundary);
		}
		if (args.output_append_offset.has_value() && std::holds_alternative<std::string_view>(args.output_append_offset.value())) {
			/* FIXME: Ensure `&args.output_append_offset.value()` isn't UB */
			symbolRefTable.emplace_back(std::get<std::string_view>(args.output_append_offset.value()), &args.output_append_offset.value());
		}
		if (args.output_append_ref_offset.has_value() && std::holds_alternative<std::string_view>(args.output_append_ref_offset.value())) {
			/* FIXME: Ensure `&args.output_append_offset.value()` isn't UB */
			symbolRefTable.emplace_back(std::get<std::string_view>(args.output_append_ref_offset.value()), &args.output_append_ref_offset.value());
		}
	}

	/* -------------------------------------- */
	/* PHASE 2: Parse symbols from input file */
	/* -------------------------------------- */

	SymbolTable symbolTable(offsetConversionOpts, symbolRefTable);
	try {
		std::unique_ptr<InputWrapper> inputWrapper;
		switch (Utils::hash(args.input_format)) {
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
				throw std::runtime_error(std::format("Unknown input format specifier: {}", args.input_format));
		}

		std::ifstream fileStream;
		std::istream& inputStream = (std::string_view(args.input_file) == "-")
			? (
				Logger::info("Reading symbols from: <STDIN> ({} format)...", args.input_format),
				std::cin
			  ) // "-" instead of a file name fallbacks to `stdin`
			: (
				Logger::info("Reading symbols from file: \"{}\" ({} format)...", args.input_file, args.input_format),
				fileStream.open(args.input_file, inputWrapper->preferredStreamMode),
				fileStream
			  );
		if (inputStream.fail()) {
			throw std::runtime_error("Failed to open input file");
		}

		inputWrapper->parseOptions(args.input_options);
		inputWrapper->parse(symbolTable, inputStream);
	}
	catch (const std::exception& err) {
		Logger::error("Input parsing failed: {}", err.what());
		return -1;
	}

	/* Make sure all symbols referenced in options (e.g. `-ref`, `-org`, `-range`), if any, were resolved */
	for (const auto & [label, target] : symbolRefTable) {
		if (std::holds_alternative<std::string_view>(*target)) {	// if still a label (string), that's a failure
			Logger::error("Referenced symbol not found: \"{}\"", label);
			return -2;
		}
	}

	/* Sort symbol table by offset */
	symbolTable.sortByOffset();

	/* If symbol-based range was used `-range @[start] @[end]`, filter out by this new range now that symbol offsets are resolved */
	if (
		offsetConversionOpts.offsetLowBoundary != std::get<uint32_t>(args.offset_low_boundary) ||
		offsetConversionOpts.offsetHighBoundary != std::get<uint32_t>(args.offset_high_boundary)
	) {
		offsetConversionOpts.offsetLowBoundary = std::get<uint32_t>(args.offset_low_boundary);
		offsetConversionOpts.offsetHighBoundary = std::get<uint32_t>(args.offset_high_boundary);
		/* FIXME: Consider optimizing this into extracting subspan from `symbolTable.data` since offsets are sorted */
		std::erase_if(symbolTable.data, [&](const SymbolTable::Record& symbol) {
			return !(symbol.offset >= offsetConversionOpts.offsetLowBoundary && symbol.offset <= offsetConversionOpts.offsetHighBoundary);
		});
	}

	/* Sanity check: Make sure offset range is correct */
	if (offsetConversionOpts.offsetLowBoundary > offsetConversionOpts.offsetHighBoundary) {
		Logger::error("Invalid \"-range\" (low > high): ${:X} ${:X}", offsetConversionOpts.offsetLowBoundary, offsetConversionOpts.offsetHighBoundary);
		return -4;
	}

	Logger::info("Read {:d} symbols.\n", symbolTable.data.size());

	/* Pre-filter symbols based on regular expression */
	if (!args.filter_regex.expression.empty()) {
		Logger::info("Filtering symbols based on regex: \"{}\"...", args.filter_regex.expression);

		int pcre2ErrorCode = 0;
		std::size_t pcre2ErrorOffset = 0;
		pcre2_code* pcre2RegexCode = pcre2_compile(
			reinterpret_cast<PCRE2_SPTR8>(args.filter_regex.expression.data()),
			args.filter_regex.expression.size(),
			args.filter_regex.caseInsensitive ? PCRE2_CASELESS : 0,
			&pcre2ErrorCode, &pcre2ErrorOffset, nullptr
		);
		if (!pcre2RegexCode) {
			PCRE2_UCHAR8 pcre2ErrorMessage[128];
			pcre2_get_error_message(pcre2ErrorCode, pcre2ErrorMessage, sizeof(pcre2ErrorMessage));
			// FIXME: Try-catch?
			Logger::error("Failed to compile filter regex at offset {}: {}", pcre2ErrorOffset, pcre2ErrorMessage);
			return -5;
		}

		pcre2_jit_compile(pcre2RegexCode, PCRE2_JIT_COMPLETE);

		pcre2_match_data* matchData = pcre2_match_data_create_from_pattern(pcre2RegexCode, nullptr);

		/* FIXME: Perform filtering early in `SymbolTable::add`? May hurt branching and cache locality */
		std::erase_if(symbolTable.data, [&](const SymbolTable::Record& symbol) {
			const int rc = pcre2_match(
				pcre2RegexCode,
				reinterpret_cast<PCRE2_SPTR8>(symbol.label.data()),
				symbol.label.length(),
				0,
				PCRE2_ANCHORED | PCRE2_ENDANCHORED,
				matchData, nullptr
			);
			return (rc >= 0) == args.filter_exclude_matching;
		});

		pcre2_match_data_free(matchData);
		pcre2_code_free(pcre2RegexCode);
	}


	/* ----------------------------------------- */
	/* PHASE 3: Apply transformations to symbols */
	/* ----------------------------------------- */

	/* Basic character transforms, if any (`-tolower` or `-toupper`) */
	if (args.character_transform == CharacterTransformMode::ToUpper) {
		for (auto & [_, label] : symbolTable.data) {
			std::transform(label.begin(), label.end(), const_cast<char*>(label.begin()), [](unsigned char c) { return std::toupper(c); });
		}
	}
	else if (args.character_transform == CharacterTransformMode::ToLower) {
		for (auto & [_, label] : symbolTable.data) {
			std::transform(label.begin(), label.end(), const_cast<char*>(label.begin()), [](unsigned char c) { return std::tolower(c); });
		}
	}

	/* Remove given prefix, if present (`-rmprefix`) */
	if (!args.remove_prefix.empty()) {
		const auto prefixLenth = args.remove_prefix.length();
		for (auto& [offset, label] : symbolTable.data) {
			if (label.starts_with(args.remove_prefix)) {
				label = label.substr(prefixLenth);
			}
		}
	}

	/* Add prefix to all symbols (`-addprefix`) */
	if (!args.add_prefix.empty()) {
		for (auto& [offset, label] : symbolTable.data) {
			label = symbolTable.arena.push_concat(args.add_prefix, label);
		}
	}


	/* ----------------------------------------------------- */
	/* PHASE 4: Dump resulting symbol table in output format */
	/* ----------------------------------------------------- */

	if (symbolTable.data.empty()) {
		Logger::error("No symbols passed for output, operation aborted");
		return -3;
	}

	try {
		std::unique_ptr<OutputWrapper> outputWrapper;
		switch (Utils::hash(args.output_format)) {
			case Utils::hash("log"):	outputWrapper = std::make_unique<Output__Log>(); break;
			case Utils::hash("asm"):	outputWrapper = std::make_unique<Output__Asm>(); break;
			case Utils::hash("deb2"):	outputWrapper = std::make_unique<Output__Deb2>(); break;
			case Utils::hash("deb1"):	outputWrapper = std::make_unique<Output__Deb1>();
										Logger::warn("\"deb1\" output format is deprecated, use \"deb2\" instead" ); break;
			default:
				throw std::runtime_error(std::format("Unknown output format specifier: {}", args.output_format));
		}

		/* Setup output stream respecting various append flags */
		std::FILE* outputFile;
		if (std::string_view(args.output_file) == "-") {
			outputFile = stdout;
			Logger::info("Writing symbols to: <STDOUT> ({} format)...", args.output_format);
			/* FIXME: Fail in append mode */
		}
		else {
			if (!args.output_append_end && !args.output_append_offset.has_value()) {
				outputFile = std::fopen(args.output_file, outputWrapper->preferredStreamMode == OutputWrapper::PreferredStreamMode::Text ? "w" : "wb");
				Logger::info("Writing symbols to file: \"{}\" ({} format)...", args.output_file, args.output_format);
			}
			else {
				outputFile = std::fopen(args.output_file, outputWrapper->preferredStreamMode == OutputWrapper::PreferredStreamMode::Text ? "r+" : "r+b");
				if (outputFile) {
					std::size_t appendOffset = 0;
					if (!args.output_append_offset.has_value()) {
						std::fseek(outputFile, 0, SEEK_END);
						appendOffset = std::ftell(outputFile);
						if (!args.output_append_no_align && (appendOffset & 1) != 0) {
							Logger::debug("Auto-aligning append offset.");
							std::fputc(0x00, outputFile);
							appendOffset++;
						}
					}
					else {
						appendOffset = std::get<uint32_t>(args.output_append_offset.value());
						if (!args.output_append_no_align && ((appendOffset & 1) != 0)) {
							Logger::warn("An odd append offset is specified; the offset wasn't auto-aligned.");
						}
						std::fseek(outputFile, appendOffset, SEEK_SET);
					}

					Logger::info("Appending symbols to file: \"{}\" ({} format) at offset ${:X}...", args.output_file, args.output_format, appendOffset);

					if (args.output_append_ref_offset.has_value()) {
						const auto refOffset = std::get<uint32_t>(args.output_append_ref_offset.value());
						std::fseek(outputFile, refOffset, SEEK_SET);
						const uint32_t appendOffsetBE = Utils::asBigEndian<uint32_t>(appendOffset);
						std::fwrite((const char*)&appendOffsetBE, 4, 1, outputFile);
						std::fseek(outputFile, appendOffset, SEEK_SET);
						Logger::info("Wrote append offset reference as 32-bit absolute pointer at offset ${:X}.", refOffset);
					}
				}
			}
		}
		if (!outputFile) {
			throw std::runtime_error("Failed to open output file");
		}

		outputWrapper->parseOptions(args.output_options);
		outputWrapper->parse(symbolTable.data, outputFile);

		if (outputFile != stdout) std::fclose(outputFile);
	}
	catch (const std::exception& err) {
		Logger::error("Output generation failed: {}", err.what());
		return -2;
	}

	Logger::info("Wrote {:d} symbols.", symbolTable.data.size());
	return 0;
}
