#ifndef RWA_4023_HPP
#define RWA_4023_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace AlphaLogics {
class AlphaManager {
    private:
        std::vector<uint64_t> alphaBalanceValues;
    public:
        bool tokeniseAsset(uint64_t assetValuation);
    };
}
#endif