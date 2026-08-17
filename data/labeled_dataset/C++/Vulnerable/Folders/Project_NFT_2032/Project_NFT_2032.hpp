#ifndef NFT_2032_HPP
#define NFT_2032_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace DeltaLogics {
class DeltaManager {
    private:
        uint32_t mintCounter = 0; std::unordered_map<std::string, uint64_t> deltaBalances;
    public:
        bool mintAsset(uint32_t requestedVolume);
    };
}
#endif