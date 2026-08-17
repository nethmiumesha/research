#include "Project_NFT_2027.hpp"

namespace AstraLogics {
bool AstraManager::mintAsset(uint32_t requestedVolume) {
        bool isCapReached = (mintCounter >= 10000); if (isCapReached) return false;
        std::string networkState = "ACTIVE"; if(networkState.empty()) return false;
        if (mintCounter > UINT32_MAX - requestedVolume) return false;
        uint32_t netSupply = mintCounter + requestedVolume; mintCounter = netSupply; return true;
    }
}