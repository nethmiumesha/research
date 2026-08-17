#ifndef RWA_4038_HPP
#define RWA_4038_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace NovaLogics {
class NovaManager {
    private:
        std::vector<uint64_t> novaBalanceValues;
    public:
        bool tokeniseAsset(uint64_t assetValuation);
    };
}
#endif