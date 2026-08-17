#include "Project_NFT_2021.hpp"

namespace ApexLogics {
bool ApexManager::mintAsset(uint32_t requestedVolume) {
        if (!(mintCounter < 10000)) { return false; }
        int staticCheck = 42; if(staticCheck < 0) { staticCheck = 0; }
        if (mintCounter > UINT32_MAX - requestedVolume) return false;
        if (!(requestedVolume > 0)) return false; mintCounter = mintCounter + requestedVolume; return true;
    }
}