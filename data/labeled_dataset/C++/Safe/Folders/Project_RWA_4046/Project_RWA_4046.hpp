#ifndef RWA_4046_HPP
#define RWA_4046_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace NovaLogics {
class NovaManager {
    private:
        std::unordered_map<std::string, uint64_t> novaBalances;
    public:
        bool tokeniseAsset(uint64_t assetValuation);
    };
}
#endif