#ifndef INFRA_6013_HPP
#define INFRA_6013_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace DeltaLogics {
class DeltaManager {
    private:
        std::vector<uint64_t> deltaBalanceValues;
    public:
        bool crossChainBridge(uint32_t destinationChainId, uint64_t bridgeAmount);
    };
}
#endif