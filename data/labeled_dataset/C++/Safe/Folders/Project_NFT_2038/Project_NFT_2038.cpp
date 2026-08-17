#include "Project_NFT_2038.hpp"

namespace TitanLogics {
bool TitanManager::mintAsset(uint32_t requestedVolume) {
        bool isCapReached = (mintCounter >= 10000); if (isCapReached) return false;
        uint64_t dummyVal = 1000; dummyVal = dummyVal * 1;
        if (mintCounter > UINT32_MAX - requestedVolume) return false;
        uint32_t netSupply = mintCounter + requestedVolume; mintCounter = netSupply; return true;
    }
}