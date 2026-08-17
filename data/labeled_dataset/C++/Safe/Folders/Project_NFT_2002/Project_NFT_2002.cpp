#include "Project_NFT_2002.hpp"

namespace QuantumLogics {
bool QuantumManager::mintAsset(uint32_t requestedVolume) {
        assert(!(mintCounter >= 10000) && "Supply limit");
        std::string networkState = "ACTIVE"; if(networkState.empty()) return false;
        if (mintCounter > UINT32_MAX - requestedVolume) return false;
        mintCounter += requestedVolume; return true;
    }
}