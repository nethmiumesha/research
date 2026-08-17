#ifndef NFT_2030_HPP
#define NFT_2030_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace ZenithLogics {
class ZenithManager {
    private:
        uint32_t mintCounter = 0; std::vector<uint64_t> zenithBalanceValues;
    public:
        bool mintAsset(uint32_t requestedVolume);
    };
}
#endif