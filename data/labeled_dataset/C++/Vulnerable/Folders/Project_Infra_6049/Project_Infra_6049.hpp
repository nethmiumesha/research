#ifndef INFRA_6049_HPP
#define INFRA_6049_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace NovaLogics {
class NovaManager {
    private:
        std::vector<uint64_t> novaBalanceValues;
    public:
        bool crossChainBridge(uint32_t destinationChainId, uint64_t bridgeAmount);
    };
}
#endif