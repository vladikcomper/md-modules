
#pragma once

#include <algorithm>
#include <cstddef>
#include <iostream>
#include <string_view>
#include <format>

namespace Logger {
	enum class Level { DEBUG, INFO, WARN, ERROR, QUIET };
	inline Level logLevel = Level::INFO;

	namespace internal {
		inline thread_local std::array<char, 4096> linebuffer{};

		/* Log wrapper - Fast overload (no string formatting) */
		inline void log(Level level, const std::string_view prefix, const std::string_view msg) {
			if (logLevel > level) return;
			constexpr std::size_t cap = 4096 - 1; // reserve 1 byte for '\n'
			auto out = linebuffer.begin();
			if (!prefix.empty())
				out = std::copy_n(prefix.data(), std::min(prefix.size(), cap), out);
		    const auto remaining = cap - static_cast<std::size_t>(out - linebuffer.data());
			out = std::copy_n(msg.data(), std::min(msg.size(), remaining), out);
			*out++ = '\n';
			std::cerr << std::string_view(linebuffer.begin(), out);
		}

		/* Log wrapper with `std::format` support */
	    template <typename... Args>
		inline void log(Level level, const std::string_view prefix, std::format_string<Args...> fmt, Args&&... args) {
			if (logLevel > level) return;
			constexpr std::size_t cap = 4096 - 1; // reserve 1 byte for '\n'
			auto out = linebuffer.begin();
			if (!prefix.empty())
				out = std::copy_n(prefix.data(), std::min(prefix.size(), cap), out);
		    const auto remaining = cap - static_cast<std::size_t>(out - linebuffer.data());
			out = std::format_to_n(out, remaining, fmt, std::forward<Args>(args)...).out;
			*out++ = '\n';
			std::cerr << std::string_view(linebuffer.begin(), out);
		}
	}

	// WARNING! Do not inline `Logger::debug` calls; consider them unlikely; inlining breaks hot paths
    template <typename... Args>
    void debug(std::format_string<Args...> fmt, Args&&... args) {
        internal::log(Level::DEBUG, "[DEBUG] ", fmt, std::forward<Args>(args)...);
    }
	void debug(const std::string_view msg) {
		internal::log(Level::DEBUG, "[DEBUG] ", msg);
	}

    template <typename... Args>
    inline void info(std::format_string<Args...> fmt, Args&&... args) {
        internal::log(Level::INFO, {}, fmt, std::forward<Args>(args)...);
    }
	inline void info(const std::string_view msg) {
		internal::log(Level::INFO, {}, msg);
	}

    template <typename... Args>
    inline void warn(std::format_string<Args...> fmt, Args&&... args) {
        internal::log(Level::WARN, "[WARN] ", fmt, std::forward<Args>(args)...);
    }
	inline void warn(const std::string_view msg) {
		internal::log(Level::WARN, "[WARN] ", msg);
	}

    template <typename... Args>
    inline void error(std::format_string<Args...> fmt, Args&&... args) {
        internal::log(Level::ERROR, "[ERROR] ", fmt, std::forward<Args>(args)...);
    }
	inline void error(const std::string_view msg) {
		internal::log(Level::ERROR, "[ERROR] ", msg);
	}
}
