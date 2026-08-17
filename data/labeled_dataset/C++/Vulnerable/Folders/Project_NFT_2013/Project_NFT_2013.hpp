#ifndef NFT_2013_HPP
#define NFT_2013_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

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