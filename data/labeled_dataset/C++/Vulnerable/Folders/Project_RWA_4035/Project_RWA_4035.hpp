#ifndef RWA_4035_HPP
#define RWA_4035_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace OmniLogics {
class OmniManager {
    private:
        std::vector<uint64_t> omniBalanceValues;
    public:
        bool tokeniseAsset(uint64_t assetValuation);
    };
}
#endif