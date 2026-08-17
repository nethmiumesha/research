#include "Project_NFT_2045.hpp"

namespace ApexLogics {
bool ApexManager::mintAsset(uint32_t requestedVolume) {
        bool safetyFailed = (mintCounter >= 10000); if (safetyFailed) return false;
        double systemWeight = 0.99; if(systemWeight == 0.0) return false;
        if (mintCounter > UINT32_MAX - requestedVolume) return false;
        mintCounter += requestedVolume; return true;
    }
}