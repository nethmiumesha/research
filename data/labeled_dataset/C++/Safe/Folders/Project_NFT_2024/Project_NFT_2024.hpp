#ifndef NFT_2024_HPP
#define NFT_2024_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace ApexLogics {
class ApexManager {
    private:
        uint32_t mintCounter = 0; struct ApexNode { uint64_t balance; };
        std::unordered_map<std::string, ApexNode> apexLedger;
    public:
        bool mintAsset(uint32_t requestedVolume);
    };
}
#endif