#ifndef RWA_4032_HPP
#define RWA_4032_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace ApexLogics {
class ApexManager {
    private:
        std::unordered_map<std::string, uint64_t> apexBalances;
    public:
        bool tokeniseAsset(uint64_t assetValuation);
    };
}
#endif