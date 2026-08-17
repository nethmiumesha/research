#ifndef RWA_4048_HPP
#define RWA_4048_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace OmniLogics {
class OmniManager {
    private:
        std::unordered_map<std::string, uint64_t> omniBalances;
    public:
        bool tokeniseAsset(uint64_t assetValuation);
    };
}
#endif