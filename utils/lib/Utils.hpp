#pragma once

#include <bit>
#include <cassert>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <istream>
#include <memory>
#include <new>
#include <string>
#include <string_view>
#include <vector>

namespace Utils {

	/*
	 * Ensures the result uses Big Endian byte order. This is a no-op on Big Endian systems.
	 */
	template<typename T>
	inline constexpr T asBigEndian(T value) {
		return std::endian::native == std::endian::little ? std::byteswap<T>(value) : value;
	}

	/* 
	 * Same as `std::getline`, but works for `\r\n` (CRLF-style line endings) on Linux/Mac,
	 * which allows to safely parse files generated on Windows.
	 */
	inline std::istream& getline_safe(std::istream& is, std::string& line) {
		auto& result = std::getline(is, line);
		if (result && !line.empty() && line.back() == '\r') {
			line.pop_back();
		}
		return result;
	}

	/**
	 * Simple compile-time hash functions for strings (djb2 algorithm)
	 */
	inline constexpr uint32_t hash(std::string_view str) {
	    uint32_t hash = 5381;
	    for (char c : str) {
	        hash = ((hash << 5) + hash) + static_cast<uint32_t>(c);
	    }

	    return hash;
	}

	/**
	 * An alternative to `std::size` which also supports `char`
	 */
	inline constexpr std::size_t length(std::string_view sv) { return sv.size(); }
	inline constexpr std::size_t length(char c) { return 1; }

	/**
	 * Arena optimized for efficient continous string storage (in 64 KiB chunks)
	 * Storage may only grow and de-allocation is not possible.
	 */
	class StringArena {
		static const std::size_t chunkSize = 0x10000;	// bytes
		std::vector<std::unique_ptr<char[]>> arenaPtrs;
		std::size_t currentArenaPos = chunkSize;

		static char* _concat(char* buff, std::string_view sv) { std::memcpy(buff, sv.data(), sv.size()); return buff+sv.size(); }
		static char* _concat(char* buff, char c) { *buff++ = c; return buff; }

	public:
		StringArena() {	arenaPtrs.reserve(16); }
		StringArena(const StringArena&) = delete;
		StringArena& operator=(const StringArena&) = delete;

		inline char* allocate(std::size_t allocSize) {
			if (allocSize > chunkSize) throw std::bad_alloc();
			if (currentArenaPos + allocSize > chunkSize) {
				arenaPtrs.push_back(std::make_unique<char[]>(chunkSize));
				currentArenaPos = 0;
			}
			char* startPtr = &arenaPtrs.back()[currentArenaPos];
			currentArenaPos += allocSize;
			return startPtr;
		}

		inline std::string_view push(std::string_view sv) {
			char* startPtr = allocate(sv.size() + 1);	// + null-terminator
			std::memcpy(startPtr, sv.data(), sv.size());
			return std::string_view(startPtr, sv.size());
		}

		template<typename ...Parts>
		inline std::string_view push_concat(Parts&&... parts) {
			const std::size_t fullLen = (length(parts) + ...);
			char* startPtr = allocate(fullLen + 1);
			char* curr = startPtr;
			((curr = _concat(curr, parts)), ...);
			assert(curr == startPtr + fullLen);
			return std::string_view(startPtr, fullLen);
		}
	};
}
