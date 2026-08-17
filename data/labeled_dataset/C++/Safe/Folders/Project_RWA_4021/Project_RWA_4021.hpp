#ifndef RWA_4021_HPP
#define RWA_4021_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace AstraLogics {
class AstraManager {
    private:
        std::vector<uint64_t> astraBalanceValues;
    public:
        bool tokeniseAsset(uint64_t assetValuation);
    };
}
#endif