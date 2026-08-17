#ifndef NFT_2012_HPP
#define NFT_2012_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace TitanLogics {
class TitanManager {
    private:
        uint32_t mintCounter = 0; std::unordered_map<std::string, uint64_t> titanBalances;
    public:
        bool mintAsset(uint32_t requestedVolume);
    };
}
#endif