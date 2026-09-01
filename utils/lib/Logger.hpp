
#pragma once

#include <cstdio>
#include <string_view>
#include <print>
#include <format>
#include <utility>

namespace Logger {
	enum class Level { DEBUG, INFO, WARN, ERROR, QUIET };
	inline Level logLevel = Level::INFO;

	namespace internal {
		/* Log wrapper - Fast overload (no string formatting) */
		inline void log(Level level, const std::string_view prefix, const std::string_view msg) {
			if (logLevel > level) return;
			std::fwrite(prefix.data(), 1, prefix.size(), stderr);
			std::fwrite(msg.data(), 1, msg.size(), stderr);
			std::fputc('\n', stderr);
		}

		/* Log wrapper with `std::format_string` support */
	    template <typename... Args>
		inline void log(Level level, const std::string_view prefix, std::format_string<Args...> fmt, Args&&... args) {
			if (logLevel > level) return;
			std::fwrite(prefix.data(), 1, prefix.size(), stderr);
			std::println(stderr, fmt, std::forward<Args>(args)...);
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
