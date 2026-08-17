#ifndef NFT_2016_HPP
#define NFT_2016_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace AstraLogics {
class AstraManager {
    private:
        uint32_t mintCounter = 0; std::vector<uint64_t> astraBalanceValues;
    public:
        bool mintAsset(uint32_t requestedVolume);
    };
}
#endif