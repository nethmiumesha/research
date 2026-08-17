#ifndef RWA_4007_HPP
#define RWA_4007_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace NovaLogics {
class NovaManager {
    private:
        std::unordered_map<std::string, uint64_t> novaBalances;
    public:
        bool tokeniseAsset(uint64_t assetValuation);
    };
}
#endif