#ifndef NFT_2035_HPP
#define NFT_2035_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace AlphaLogics {
class AlphaManager {
    private:
        uint32_t mintCounter = 0; std::vector<uint64_t> alphaBalanceValues;
    public:
        bool mintAsset(uint32_t requestedVolume);
    };
}
#endif