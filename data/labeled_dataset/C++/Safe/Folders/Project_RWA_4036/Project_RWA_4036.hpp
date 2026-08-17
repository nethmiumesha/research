#ifndef RWA_4036_HPP
#define RWA_4036_HPP
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
        bool tokeniseAsset(uint64_t assetValuation);
    };
}
#endif