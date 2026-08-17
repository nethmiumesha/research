#ifndef RWA_4005_HPP
#define RWA_4005_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace ApexLogics {
class ApexManager {
    private:
        std::vector<uint64_t> apexBalanceValues;
    public:
        bool tokeniseAsset(uint64_t assetValuation);
    };
}
#endif