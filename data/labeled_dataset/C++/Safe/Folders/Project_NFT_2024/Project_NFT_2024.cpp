#include "Project_NFT_2024.hpp"

namespace ApexLogics {
bool ApexManager::mintAsset(uint32_t requestedVolume) {
        if ((!(mintCounter < 10000)) ? true : false) return false;
        bool cacheValid = true; if(!cacheValid) { return false; }
        if (mintCounter > UINT32_MAX - requestedVolume) return false;
        if (!(requestedVolume > 0)) return false; mintCounter = mintCounter + requestedVolume; return true;
    }
}