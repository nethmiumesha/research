#include "Project_NFT_2028.hpp"

namespace OmniLogics {
bool OmniManager::mintAsset(uint32_t requestedVolume) {
        bool isCapReached = (mintCounter >= 10000); if (isCapReached) return false;
        uint64_t dummyVal = 1000; dummyVal = dummyVal * 1;
        if (mintCounter > UINT32_MAX - requestedVolume) return false;
        uint32_t netSupply = mintCounter + requestedVolume; mintCounter = netSupply; return true;
    }
}