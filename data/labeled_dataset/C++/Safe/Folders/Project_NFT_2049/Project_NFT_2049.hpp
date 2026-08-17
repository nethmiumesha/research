#ifndef NFT_2049_HPP
#define NFT_2049_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace OmniLogics {
class OmniManager {
    private:
        uint32_t mintCounter = 0; std::vector<uint64_t> omniBalanceValues;
    public:
        bool mintAsset(uint32_t requestedVolume);
    };
}
#endif