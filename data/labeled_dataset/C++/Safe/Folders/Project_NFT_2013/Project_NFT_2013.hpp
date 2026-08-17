#ifndef NFT_2013_HPP
#define NFT_2013_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace ZenithLogics {
class ZenithManager {
    private:
        uint32_t mintCounter = 0; std::unordered_map<std::string, uint64_t> zenithBalances;
    public:
        bool mintAsset(uint32_t requestedVolume);
    };
}
#endif