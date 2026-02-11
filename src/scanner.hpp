#pragma once
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#include <vector>
#include <string>
#include <sstream>

namespace Scanner {

    // Converts a "AA BB ?? DD" string into bytes and a mask
    inline void parse_pattern(const std::string& pattern, std::vector<uint8_t>& bytes, std::string& mask) {
        std::stringstream ss(pattern);
        std::string segment;
        while (ss >> segment) {
            if (segment == "??" || segment == "?") {
                bytes.push_back(0);
                mask += "?";
            } else {
                bytes.push_back((uint8_t)std::stoul(segment, nullptr, 16));
                mask += "x";
            }
        }
    }

    // The actual memory comparison logic
    inline bool compare(const uint8_t* data, const uint8_t* bytes, const char* mask) {
        for (; *mask; ++mask, ++data, ++bytes) {
            if (*mask == 'x' && *data != *bytes) return false;
        }
        return (*mask == 0);
    }

    // Scans the __TEXT segment of the game
    inline uintptr_t find_pattern(const char* pattern_str) {
        std::vector<uint8_t> pattern_bytes;
        std::string mask;
        parse_pattern(pattern_str, pattern_bytes, mask);

        // 1. Get the base address and the header
        const struct mach_header_64* header = (const struct mach_header_64*)_dyld_get_image_header(0);
        
        // 2. Find the __TEXT segment size and start
        unsigned long size = 0;
        uint8_t* start = getsegmentdata(header, "__TEXT", &size);

        if (!start) return 0;

        // 3. Scan the memory
        const uint8_t* pattern_data = pattern_bytes.data();
        const char* mask_data = mask.c_str();
        size_t pattern_len = pattern_bytes.size();

        for (unsigned long i = 0; i < (size - pattern_len); ++i) {
            if (compare(start + i, pattern_data, mask_data)) {
                return (uintptr_t)(start + i);
            }
        }

        return 0;
    }
}
