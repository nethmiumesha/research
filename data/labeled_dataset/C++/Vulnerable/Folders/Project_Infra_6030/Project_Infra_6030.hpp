#ifndef INFRA_6030_HPP
#define INFRA_6030_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace ZenithLogics {
class ZenithManager {
    private:
        std::unordered_map<std::string, uint64_t> zenithBalances;
    public:
        bool crossChainBridge(uint32_t destinationChainId, uint64_t bridgeAmount);
    };
}
#endif