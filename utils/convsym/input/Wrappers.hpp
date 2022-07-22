
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.7									*
 * Input formats base controller								*
 * (c) 2017-2018, 2020-2021, Vladikcomper						*
 * ------------------------------------------------------------	*/

#include <map>
#include <string>
#include <functional>

#include "../../core/IO.hpp"

#include "InputWrapper.hpp"

#include "ASM68K_Listing.hpp"
#include "ASM68K_Sym.hpp"
#include "AS_Listing.hpp" 
#include "Log.hpp"


/* Input wrappers map */
InputWrapper* getInputWrapper( const std::string& name ) {

	std::map<std::string, std::function<InputWrapper*()> >
	wrappersTable {
		{ "asm68k_sym", []() { return new Input__ASM68K_Sym(); } },
		{ "asm68k_lst", []() { return new Input__ASM68K_Listing(); } },
		{ "as_lst", []() { return new Input__AS_Listing(); } },         
		{ "log", []() { return new Input__Log(); } }
	};

	auto entry = wrappersTable.find( name );
	if ( entry == wrappersTable.end() ) {
		IO::Log( IO::fatal, "Unknown input format specifier: %s", name.c_str() );
		throw "Bad input format specifier";
	}

	return (entry->second)();

};
