
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.0									*
 * Input formats base controller								*
 * (c) 2017, Vladikcomper										*
 * ------------------------------------------------------------	*/

/* Base class for the input formats handlers */
struct InputWrapper {

	InputWrapper() { }
	virtual ~InputWrapper() { }

	// Virtual function interface that handles input file parsing
	virtual map<uint32_t, string>
		parse( const char *fileName, uint32_t baseOffset, uint32_t offsetLeftBoundary, uint32_t offsetRightBoundary, const char * opts ) = 0;

};

/* Standard input wrappers */
#include "ASM68K_Listing.hpp"
#include "ASM68K_Sym.hpp"
#include "AS_Listing.hpp"

/* Input wrappers map */
InputWrapper* getInputWrapper( const char * name ) {

	map<string, function<InputWrapper*()> >
	wrappersTable {
		{ "asm68k_sym", []() { return new Input__ASM68K_Sym(); } },
		{ "asm68k_lst", []() { return new Input__ASM68K_Listing(); } },
		{ "as_lst", []() { return new Input__AS_Listing(); } }
	};

	auto entry = wrappersTable.find( name );
	if ( entry == wrappersTable.end() ) {
		IO::Log( IO::fatal, "Unknown input format specifier: %s", name );
		throw "Bad input format specifier";
	}

	return (entry->second)();

};
