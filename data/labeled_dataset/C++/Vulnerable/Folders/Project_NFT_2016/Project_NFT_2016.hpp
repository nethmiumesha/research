#ifndef NFT_2016_HPP
#define NFT_2016_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace AstraLogics {
class AstraManager {
    private:
        uint32_t mintCounter = 0; struct AstraNode { uint64_t balance; };
        std::unordered_map<std::string, AstraNode> astraLedger;
    public:
        bool mintAsset(uint32_t requestedVolume);
    };
}
#endif