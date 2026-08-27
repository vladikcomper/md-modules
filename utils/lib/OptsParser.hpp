
/* ------------------------------------------------------------ *
 * Debugging Modules Utilities Core								*
 * Options parser helper class									*
 * (c) 2017-2018, Vladikcomper									*
 * ------------------------------------------------------------	*/

#pragma once

#include <map>
#include <stdexcept>
#include <string>

#include "Logger.hpp"

/* FIXME: Refactor */
namespace OptsParser {

	/* Structure that handles option definition */
	struct record {
		enum { p_bool, p_char, p_string } type;
		void * target;
	};

	/**
	 * Function to parse string consisting of options and their values
	 */
	void parse(const char* opts, const std::map<std::string, record>& OptsList) {

		const char * ptr = opts;
		bool illegalCharactersFound = false;
		
		#define IS_VALID_OPERATOR(X) (X=='='||X=='+'||X=='-')

		while ( *ptr ) {

			// Fetch option start token
			if ( *ptr == '/' ) {

				const char *ptr_start, *ptr_end;

				// Fetch option name
				ptr_start = ++ptr;
				while ( !IS_VALID_OPERATOR(*ptr) && *ptr ) ptr++;
				std::string strOptionName( ptr_start, ptr-ptr_start );
				
				// Fetch option operator
				char cOptionOperator = *ptr;

				// Fetch option value
				ptr_start = ++ptr;
				if ( *ptr == '\'' ) {		// if quote fetched, seek for closing quote, capture string inbetween
					ptr_start = ++ptr;			// correct string pointer to pass the quote itself ...
					while ( *ptr!='\'' && *ptr ) ptr++;
					ptr_end = ptr;
					if ( !*ptr ) {				// if string ended before fetching a closing quote, issue error
						Logger::warn("Missed closing quote for value of parameter {}", strOptionName);
					}
					else {						// otherwise, skip the quote
						ptr++;
					}
				}
				else {						// otherwise, seek for space
					while ( *ptr!=' ' && *ptr ) ptr++;
					ptr_end = ptr;
				}
				std::string strOptionValue( ptr_start, ptr_end-ptr_start );

				// Decode option according to the options list
				auto option = OptsList.find(strOptionName);
				if ( option != OptsList.end() ) {
					switch ( option->second.type ) {
						
						case record::p_bool:
							*((bool*)option->second.target) = (cOptionOperator == '+');
							break;

						case record::p_char:
							*((char*)option->second.target) = strOptionValue[0];
							break;

						case record::p_string:
							*((std::string*)option->second.target) = strOptionValue;
							break;

						default:
							throw std::runtime_error("Incorrect or broken option list entry");

					}
				}
				else {
					Logger::error("Unknown option: /{}, skipping", strOptionName);
				}
			}

			// ... otherwise
			else {

				// If character is not a whitespace, issue warning once
				if ( *ptr!=' ' ) {
					if ( illegalCharactersFound == false ) {
						illegalCharactersFound = true;
						Logger::warn("Illegal characters found while parsing option string");
					}
				}
	
				// Skip character
				ptr++;
			}
		}

	}

}