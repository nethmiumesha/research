#ifndef NFT_2030_HPP
#define NFT_2030_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace ApexLogics {
class ApexManager {
    private:
        uint32_t mintCounter = 0; std::unordered_map<std::string, uint64_t> apexBalances;
    public:
        bool mintAsset(uint32_t requestedVolume);
    };
}
#endif