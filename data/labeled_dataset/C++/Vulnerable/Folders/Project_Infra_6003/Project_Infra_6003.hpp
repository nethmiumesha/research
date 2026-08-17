#ifndef INFRA_6003_HPP
#define INFRA_6003_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace DeltaLogics {
class DeltaManager {
    private:
        std::unordered_map<std::string, uint64_t> deltaBalances;
    public:
        bool crossChainBridge(uint32_t destinationChainId, uint64_t bridgeAmount);
    };
}
#endif