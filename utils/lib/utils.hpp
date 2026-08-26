#pragma once

#include <cstdint>
#include <istream>
#include <string>

inline uint16_t swap16(uint16_t x) { return (x>>8)|(x<<8); }
inline uint32_t swap32(uint32_t x) { return (x>>24)|((x>>8)&0xFF00)|((x<<8)&0xFF0000)|(x<<24); }

/* 
 * Same as `std::getline`, but works for `\r\n` (CRLF-style line endings) on Linux/Mac, which
 * allows to safely parse files generated on Windows.
 */
inline std::istream& getline_safe(std::istream& is, std::string& line) {
	auto& result = std::getline(is, line);
	if (result && !line.empty() && line.back() == '\r') {
		line.pop_back();
	}
	return result;
}
