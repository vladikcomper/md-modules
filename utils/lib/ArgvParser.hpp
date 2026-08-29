
/* ------------------------------------------------------------ *
 * Debugging Modules Utilities Core								*
 * Argument values parser helper 								*
 * (c) 2017-2026, Vladikcomper									*
 * ------------------------------------------------------------	*/

#pragma once

#include <stdexcept>
#include <variant>
#include <format>
#include <string>
#include <vector>


namespace ArgvParser {

	namespace Arg {
		namespace internal {
			inline uint32_t parseHex(std::string_view name, std::string_view value) {
				if (value.starts_with("0x") || value.starts_with("0X"))
					value.remove_prefix(2);
				uint32_t result = 0;
				const auto [ptr, ec] = std::from_chars(value.data(), value.data() + value.size(), result, 16);
				if (ec != std::errc{} || ptr != value.data() + value.size())
					throw std::runtime_error(std::format("Parameter \"{}\": failed to parse hex number: {}", name, value));
				return result;
			}
		}

		struct flag {
			bool* target;
			inline void operator()(const std::string_view, auto&&) const { *target = true; }
		};

		struct hexNumber {
			uint32_t* target;
			inline void operator()(const std::string_view name, auto&& next) const { *target = internal::parseHex(name, next()); }
		};

		struct hexRange {
			uint32_t* low;
			uint32_t* high;
			inline void operator()(const std::string_view name, auto&& next) const {
				*low = internal::parseHex(name, next());
				*high = internal::parseHex(name, next());
				if (*low >= *high) {
					throw std::runtime_error(std::format("Parameter \"{}\": invalid hex range (low >= high): {:X} {:X}", name, *low, *high));
				}
			}
		};

		struct string {
			/* FIXME: Convert to `std::string_view` or leave as `const char *` */
			std::string* target;
			inline void operator()(const std::string_view, auto&& next) const { *target = next(); }
		};

		struct stringList {
			/* FIXME: Convert to `std::vector<std::string_view>` */
			std::vector<std::string>* target;
			inline void operator()(const std::string_view, auto&& next) const { target->emplace_back(next()); }
		};
	}

	struct entry {
		std::string_view name;
		std::variant<Arg::flag, Arg::hexNumber, Arg::hexRange, Arg::string, Arg::stringList> def;
	};

	/**
	 * Function to parse command line arguments (argv, argc) according to parameter data structures
	 */
	inline void parse(const char** argv, int argc, std::initializer_list<entry> parameters) {
		for (int i = 0; i < argc; ++i) {
			const std::string_view name = argv[i];

			const auto it = std::ranges::find(parameters, name, &entry::name);
			if (it == parameters.end())
				throw std::runtime_error(std::format("Unknown parameter \"{}\" passed", name));

			auto next = [&]() -> std::string_view {
				if (++i == argc)
					throw std::runtime_error(std::format("Expected value for parameter \"{}\"", name));
				return argv[i];
			};

			/* Parse argument's value using `operator()` overload in argument struct definition */
			std::visit([&](auto&& def) { def(name, next); }, it->def);
		}
	}
}