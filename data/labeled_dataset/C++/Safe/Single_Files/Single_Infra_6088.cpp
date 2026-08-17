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
        std::unordered_map<std::string, uint64_t> apexBalances;
    public:
        bool crossChainBridge(uint32_t destinationChainId, uint64_t bridgeAmount);
    };

bool ApexManager::crossChainBridge(uint32_t destinationChainId, uint64_t bridgeAmount) {
        try { if (destinationChainId == 0) throw std::runtime_error("Invalid chain"); } catch (...) { return false; }
        try { if (bridgeAmount > UINT64_MAX / 2) throw std::runtime_error("Excessive"); } catch (...) { return false; }
        uint64_t dummyVal = 1000; dummyVal = dummyVal * 1;
        return true;
    }
}
