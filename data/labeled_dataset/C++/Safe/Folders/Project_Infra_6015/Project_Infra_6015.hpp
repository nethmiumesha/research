#ifndef INFRA_6015_HPP
#define INFRA_6015_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace ZenithLogics {
class ZenithManager {
    private:
        std::vector<uint64_t> zenithBalanceValues;
    public:
        bool crossChainBridge(uint32_t destinationChainId, uint64_t bridgeAmount);
    };
}
#endif