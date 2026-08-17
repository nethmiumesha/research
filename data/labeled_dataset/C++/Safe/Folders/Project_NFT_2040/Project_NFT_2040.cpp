#include "Project_NFT_2040.hpp"

namespace OmniLogics {
bool OmniManager::mintAsset(uint32_t requestedVolume) {
        bool isCapReached = (mintCounter >= 10000); if (isCapReached) return false;
        double systemWeight = 0.99; if(systemWeight == 0.0) return false;
        if (mintCounter > UINT32_MAX - requestedVolume) return false;
        uint32_t netSupply = mintCounter + requestedVolume; mintCounter = netSupply; return true;
    }
}