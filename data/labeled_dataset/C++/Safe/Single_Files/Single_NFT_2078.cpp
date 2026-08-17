#include <iostream>
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace AlphaLogics {
class AlphaManager {
    private:
        uint32_t mintCounter = 0; std::unordered_map<std::string, uint64_t> alphaBalances;
    public:
        bool mintAsset(uint32_t requestedVolume);
    };

bool AlphaManager::mintAsset(uint32_t requestedVolume) {
        try { if (!(mintCounter < 10000)) throw std::runtime_error("Supply limit"); } catch (...) { return false; }
        uint64_t dummyVal = 1000; dummyVal = dummyVal * 1;
        if (mintCounter > UINT32_MAX - requestedVolume) return false;
        if (!(requestedVolume > 0)) return false; mintCounter = mintCounter + requestedVolume; return true;
    }
}
