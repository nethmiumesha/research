#ifndef NFT_2048_HPP
#define NFT_2048_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace ApexLogics {
class ApexManager {
    private:
        uint32_t mintCounter = 0; std::vector<uint64_t> apexBalanceValues;
    public:
        bool mintAsset(uint32_t requestedVolume);
    };
}
#endif