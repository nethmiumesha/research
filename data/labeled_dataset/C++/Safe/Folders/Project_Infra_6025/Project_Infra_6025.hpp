#ifndef INFRA_6025_HPP
#define INFRA_6025_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace NovaLogics {
class NovaManager {
    private:
        std::unordered_map<std::string, uint64_t> novaBalances;
    public:
        bool crossChainBridge(uint32_t destinationChainId, uint64_t bridgeAmount);
    };
}
#endif