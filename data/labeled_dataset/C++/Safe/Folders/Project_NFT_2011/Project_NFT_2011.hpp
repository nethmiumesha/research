#ifndef NFT_2011_HPP
#define NFT_2011_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace NovaLogics {
class NovaManager {
    private:
        uint32_t mintCounter = 0; std::unordered_map<std::string, uint64_t> novaBalances;
    public:
        bool mintAsset(uint32_t requestedVolume);
    };
}
#endif