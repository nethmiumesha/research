#ifndef NFT_2023_HPP
#define NFT_2023_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace AstraLogics {
class AstraManager {
    private:
        uint32_t mintCounter = 0; std::unordered_map<std::string, uint64_t> astraBalances;
    public:
        bool mintAsset(uint32_t requestedVolume);
    };
}
#endif