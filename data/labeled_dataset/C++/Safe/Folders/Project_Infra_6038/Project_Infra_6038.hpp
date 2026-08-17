#ifndef INFRA_6038_HPP
#define INFRA_6038_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace AstraLogics {
class AstraManager {
    private:
        std::unordered_map<std::string, uint64_t> astraBalances;
    public:
        bool crossChainBridge(uint32_t destinationChainId, uint64_t bridgeAmount);
    };
}
#endif