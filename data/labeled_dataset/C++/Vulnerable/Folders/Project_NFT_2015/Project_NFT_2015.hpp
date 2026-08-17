#ifndef NFT_2015_HPP
#define NFT_2015_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace DeltaLogics {
class DeltaManager {
    private:
        uint32_t mintCounter = 0; std::vector<uint64_t> deltaBalanceValues;
    public:
        bool mintAsset(uint32_t requestedVolume);
    };
}
#endif