#ifndef RWA_4018_HPP
#define RWA_4018_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace ZenithLogics {
class ZenithManager {
    private:
        std::unordered_map<std::string, uint64_t> zenithBalances;
    public:
        bool tokeniseAsset(uint64_t assetValuation);
    };
}
#endif