
/* ------------------------------------------------------------ *
 * Debugging Modules Utilities Core								*
 * Options parser helper class									*
 * (c) 2017-2026, Vladikcomper									*
 * ------------------------------------------------------------	*/

#pragma once

#include <algorithm>
#include <cctype>
#include <format>
#include <initializer_list>
#include <stdexcept>
#include <string_view>
#include <variant>


namespace OptsParser {

	namespace Opt {
		struct Char {
			char* target;
			inline void operator()(const std::string_view name, const std::string_view value) const {
				if (value.size() != 1) {
					throw std::runtime_error(std::format("Option \"/{}\": Expected a single character.", name));
				}
				*target = value[0];
			}
		};

		struct Bool {
			bool* target;
			inline void operator()(const std::string_view name, const std::string_view value) const {
				if (value.size() != 1 || !(value[0] == '-' || value[0] == '+')) {
					throw std::runtime_error(std::format("Option \"/{}\": Expected \"+\" or \"-\" as option value.", name));
				}
				*target = value[0] == '+';
			}
		};

		struct String {
			std::string_view* target;
			inline void operator()(const std::string_view, const std::string_view value) const {
				*target = value;
			}
		};
	}

	struct entry {
		std::string_view name;
		std::variant<Opt::Char, Opt::Bool, Opt::String> def;
	};

	void parse(std::string_view opts, std::initializer_list<entry> defList) {
		auto curr = opts.cbegin();
		while (curr != opts.cend()) {
			/* Skip any white space */
			while (curr != opts.cend() && (*curr == ' ' || *curr == '\t')) curr++;
			if (curr == opts.cend()) break;

			/* Fetch option name */
			if (*curr != '/') {
				throw std::runtime_error(std::format("Expected \"/\", got \"{}\"", *curr));
			}
			const auto optionNameStart = ++curr;
			while (curr != opts.cend() && std::isalnum(static_cast<unsigned char>(*curr))) curr++;
			const auto optionNameEnd = curr;
			if (optionNameStart == optionNameEnd) {
				throw std::runtime_error("Got empty option name: Expected [A-z0-9]+ after \"/\"");
			}

			const auto optionName = std::string_view(optionNameStart, optionNameEnd);
			if (curr == opts.cend() || *curr == ' ' || *curr == '\t') {
				throw std::runtime_error(std::format("Expected a value after \"/{}\"", optionName));
			}

			/* Locate option definition */
			const auto optDef = std::ranges::find(defList, optionName, &entry::name);
			if (optDef == defList.end()) {
				throw std::runtime_error(std::format("Unknown option \"/{}\"", optionName));
			}

			/* Fetch option value */
			auto optionValue = std::string_view(curr, 1);
			if (*curr++ == '=') {
				if (curr == opts.cend()) {
					throw std::runtime_error("Expected a value after \"=\"");
				}
				if (*curr == '\'') {
					const auto optionValueStart = ++curr;
					while (curr != opts.cend() && *curr != '\'') curr++;
					optionValue = std::string_view(optionValueStart, curr);
					if (curr != opts.cend() && *curr == '\'') curr++;
					else {
						throw std::runtime_error("Missing closing \"'\"");
					}
				}
				else {
					const auto optionValueStart = curr;
					while (curr != opts.cend() && *curr != ' ' && *curr != '\t') curr++;
					optionValue = std::string_view(optionValueStart, curr);
				}
			}

			/* Parse option */
			std::visit([&](auto&& def) { def(optionName, optionValue); }, optDef->def);
		}
	}

}