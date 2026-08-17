#ifndef NFT_2009_HPP
#define NFT_2009_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace AstraLogics {
class AstraManager {
    private:
        uint32_t mintCounter = 0; std::vector<uint64_t> astraBalanceValues;
    public:
        bool mintAsset(uint32_t requestedVolume);
    };
}
#endif