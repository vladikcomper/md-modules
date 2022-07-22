
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.7									*
 * Output formats base controller								*
 * (c) 2017-2018, 2020-2021, Vladikcomper						*
 * ------------------------------------------------------------	*/

#pragma once

#include <cstdint>
#include <string>
#include <map>
#include <functional>

#include "../../core/IO.hpp"

#include "OutputWrapper.hpp"
#include "DEB1.hpp"
#include "DEB2.hpp"
#include "Log.hpp"
#include "ASM.hpp"


/* Input wrappers map */
OutputWrapper* getOutputWrapper( const std::string& name ) {

	std::map<std::string, std::function<OutputWrapper*()> >
	wrappersTable {
		{ "deb1",	[]() { return new Output__Deb1();	} },
		{ "deb2",	[]() { return new Output__Deb2();	} },
		{ "log",	[]() { return new Output__Log();	} },
		{ "asm",	[]() { return new Output__Asm();	} }
	};

	auto entry = wrappersTable.find( name );
	if ( entry == wrappersTable.end() ) {
		IO::Log( IO::fatal, "Unknown output format specifier: %s", name.c_str() );
		throw "Bad output format specifier";
	}

	return (entry->second)();

};

