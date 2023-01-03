
/* ------------------------------------------------------------ *
 * ConvSym utility version 2.9									*
 * Output formats base controller								*
 * (c) 2017-2018, 2020-2023, Vladikcomper						*
 * ------------------------------------------------------------	*/

#pragma once

#include <cstdint>
#include <memory>
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
std::unique_ptr<OutputWrapper> getOutputWrapper( const std::string& name ) {

	std::map<std::string, std::function<std::unique_ptr<OutputWrapper>()> >
	wrappersTable {
		{ "deb1",	[]() { return std::unique_ptr<OutputWrapper>(new Output__Deb1());	} },
		{ "deb2",	[]() { return std::unique_ptr<OutputWrapper>(new Output__Deb2());	} },
		{ "log",	[]() { return std::unique_ptr<OutputWrapper>(new Output__Log());	} },
		{ "asm",	[]() { return std::unique_ptr<OutputWrapper>(new Output__Asm());	} }
	};

	auto entry = wrappersTable.find( name );
	if ( entry == wrappersTable.end() ) {
		IO::Log( IO::fatal, "Unknown output format specifier: %s", name.c_str() );
		throw "Bad output format specifier";
	}

	return (entry->second)();

}
