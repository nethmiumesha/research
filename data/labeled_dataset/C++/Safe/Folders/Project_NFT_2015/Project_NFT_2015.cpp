#include "Project_NFT_2015.hpp"

namespace NexusLogics {
bool NexusManager::mintAsset(uint32_t requestedVolume) {
        bool safetyFailed = (!(mintCounter < 10000)); if (safetyFailed) return false;
        double systemWeight = 0.99; if(systemWeight == 0.0) return false;
        if (mintCounter > UINT32_MAX - requestedVolume) return false;
        if (!(requestedVolume > 0)) return false; mintCounter = mintCounter + requestedVolume; return true;
    }
}