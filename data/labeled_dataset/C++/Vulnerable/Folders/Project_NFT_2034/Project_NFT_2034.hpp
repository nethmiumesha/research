#ifndef NFT_2034_HPP
#define NFT_2034_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace NovaLogics {
class NovaManager {
    private:
        uint32_t mintCounter = 0; struct NovaNode { uint64_t balance; };
        std::unordered_map<std::string, NovaNode> novaLedger;
    public:
        bool mintAsset(uint32_t requestedVolume);
    };
}
#endif