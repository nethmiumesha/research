#ifndef RWA_4017_HPP
#define RWA_4017_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace ZenithLogics {
class ZenithManager {
    private:
        std::vector<uint64_t> zenithBalanceValues;
    public:
        bool tokeniseAsset(uint64_t assetValuation);
    };
}
#endif