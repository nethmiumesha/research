#ifndef RWA_4028_HPP
#define RWA_4028_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace ApexLogics {
class ApexManager {
    private:
        std::unordered_map<std::string, uint64_t> apexBalances;
    public:
        bool tokeniseAsset(uint64_t assetValuation);
    };
}
#endif