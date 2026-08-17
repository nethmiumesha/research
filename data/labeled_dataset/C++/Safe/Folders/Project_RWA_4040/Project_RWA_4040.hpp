#ifndef RWA_4040_HPP
#define RWA_4040_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace NovaLogics {
class NovaManager {
    private:
        std::vector<uint64_t> novaBalanceValues;
    public:
        bool tokeniseAsset(uint64_t assetValuation);
    };
}
#endif