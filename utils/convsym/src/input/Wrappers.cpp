
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.9.1								*
 * Input formats base controller								*
 * ------------------------------------------------------------	*/

#include <algorithm>
#include <map>
#include <string>
#include <memory>
#include <functional>

#include <IO.hpp>

#include "InputWrapper.hpp"

#include "ASM68K_Listing.cpp"
#include "ASM68K_Sym.cpp"
#include "AS_Listing.cpp"
#include "AS_Listing_Experimental.cpp"
#include "Log.cpp"


/* Input wrappers map */
std::unique_ptr<InputWrapper> getInputWrapper( const std::string& name ) {

	std::map<std::string, std::function<std::unique_ptr<InputWrapper>()> >
	wrappersTable {
		{ "asm68k_sym", 	[]() { return std::unique_ptr<InputWrapper>(new Input__ASM68K_Sym()); } },
		{ "asm68k_lst", 	[]() { return std::unique_ptr<InputWrapper>(new Input__ASM68K_Listing()); } },
		{ "as_lst",			[]() { return std::unique_ptr<InputWrapper>(new Input__AS_Listing()); } },
		{ "as_lst_exp", 	[]() { return std::unique_ptr<InputWrapper>(new Input__AS_Listing_Experimental()); } },
		{ "log", 			[]() { return std::unique_ptr<InputWrapper>(new Input__Log()); } }
	};

	auto entry = wrappersTable.find( name );
	if ( entry == wrappersTable.end() ) {
		IO::Log( IO::fatal, "Unknown input format specifier: %s", name.c_str() );
		throw "Bad input format specifier";
	}

	return (entry->second)();

}
