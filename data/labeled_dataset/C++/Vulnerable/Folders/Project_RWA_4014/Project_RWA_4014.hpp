#ifndef RWA_4014_HPP
#define RWA_4014_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace AlphaLogics {
class AlphaManager {
    private:
        std::vector<uint64_t> alphaBalanceValues;
    public:
        bool tokeniseAsset(uint64_t assetValuation);
    };
}
#endif