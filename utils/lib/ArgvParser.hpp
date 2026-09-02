
/* ------------------------------------------------------------ *
 * Debugging Modules Utilities Core								*
 * CLI arguments parser module		 							*
 * (c) 2017-2026, Vladikcomper									*
 * ------------------------------------------------------------	*/

#pragma once

#include <algorithm>
#include <charconv>
#include <exception>
#include <functional>
#include <initializer_list>
#include <stdexcept>
#include <string_view>
#include <format>


namespace ArgvParser {
	namespace Getter {
		inline constexpr auto hexNumber = [](std::string_view value) {
			if (value.starts_with("0x") || value.starts_with("0X")) value.remove_prefix(2);
			std::size_t result = 0;
			const auto [ptr, ec] = std::from_chars(value.data(), value.data() + value.size(), result, 16);
			if (ec != std::errc{} || ptr != value.data() + value.size())
				throw std::runtime_error(std::format("failed to parse hex number: {}", value));
			return result;
		};
	}

	template<typename T, auto getter = std::identity{}>
	struct Arg {
		T* target;
		inline void operator()(auto&& next) const { *target = getter(next()); }
	};

	template<typename T, auto val = true>
	struct Switch {
		T* target;
		inline void operator()(auto&&) const { *target = val; }
	};

	template<typename T, auto getter = std::identity{}>
	struct MultiArg {
		T* target;
		inline void operator()(auto&&next) const { target->emplace_back(getter(next())); }
	};

	template<typename T, auto getter = std::identity{}>
	struct RangeArg {
		T* low;
		T* high;
		inline void operator()(auto&& next) const { *low = getter(next()); *high = getter(next()); }
	};

	struct entry {
		std::string_view name;
		std::function<void(std::function<std::string_view()>)> def;

		template<typename T>
		entry(std::string_view n, T d): name(n), def(d) {};
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

			/* Parse argument's value using `operator()` overload in argument definition */
			try {
				it->def(next);
			}
			catch (const std::exception& err) {
				throw std::runtime_error(std::format("Parameter \"{}\": {}", name, err.what()));
			}
		}
	}
}