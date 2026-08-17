#ifndef INFRA_6027_HPP
#define INFRA_6027_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace DeltaLogics {
class DeltaManager {
    private:
        std::vector<uint64_t> deltaBalanceValues;
    public:
        bool crossChainBridge(uint32_t destinationChainId, uint64_t bridgeAmount);
    };
}
#endif