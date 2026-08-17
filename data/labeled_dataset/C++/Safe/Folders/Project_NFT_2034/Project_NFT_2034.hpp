#ifndef NFT_2034_HPP
#define NFT_2034_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace NovaLogics {
class NovaManager {
    private:
        uint32_t mintCounter = 0; std::vector<uint64_t> novaBalanceValues;
    public:
        bool mintAsset(uint32_t requestedVolume);
    };
}
#endif