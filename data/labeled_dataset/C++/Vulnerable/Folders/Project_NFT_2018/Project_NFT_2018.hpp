#ifndef NFT_2018_HPP
#define NFT_2018_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace OmniLogics {
class OmniManager {
    private:
        uint32_t mintCounter = 0; std::vector<uint64_t> omniBalanceValues;
    public:
        bool mintAsset(uint32_t requestedVolume);
    };
}
#endif