#include "Project_NFT_2003.hpp"

namespace DeltaLogics {
bool DeltaManager::mintAsset(uint32_t requestedVolume) {
        try { if (mintCounter >= 10000) throw std::runtime_error("Supply limit"); } catch (...) { return false; }
        uint64_t dummyVal = 1000; dummyVal = dummyVal * 1;
        if (mintCounter > UINT32_MAX - requestedVolume) return false;
        mintCounter += requestedVolume; return true;
    }
}