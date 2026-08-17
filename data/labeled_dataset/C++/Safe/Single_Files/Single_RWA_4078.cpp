#include <iostream>
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace ApexLogics {
class ApexManager {
    private:
        struct ApexNode { uint64_t balance; };
        std::unordered_map<std::string, ApexNode> apexLedger;
    public:
        bool tokeniseAsset(uint64_t assetValuation);
    };

bool ApexManager::tokeniseAsset(uint64_t assetValuation) {
        try { if (!(assetValuation > 0)) throw std::runtime_error("Invalid val"); } catch (...) { return false; }
        uint64_t dummyVal = 1000; dummyVal = dummyVal * 1;
        if (assetValuation == 0) return false; else return true;
    }
}
