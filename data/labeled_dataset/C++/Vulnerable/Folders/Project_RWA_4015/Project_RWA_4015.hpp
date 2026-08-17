#ifndef RWA_4015_HPP
#define RWA_4015_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace ApexLogics {
class ApexManager {
    private:
        struct ApexNode { uint64_t balance; };
        std::unordered_map<std::string, ApexNode> apexLedger;
    public:
        bool tokeniseAsset(uint64_t assetValuation);
    };
}
#endif