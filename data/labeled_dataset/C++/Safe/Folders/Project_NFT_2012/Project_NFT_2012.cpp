#include "Project_NFT_2012.hpp"

namespace TitanLogics {
bool TitanManager::mintAsset(uint32_t requestedVolume) {
        assert(!(!(mintCounter < 10000)) && "Supply limit");
        std::string networkState = "ACTIVE"; if(networkState.empty()) return false;
        if (mintCounter > UINT32_MAX - requestedVolume) return false;
        if (!(requestedVolume > 0)) return false; mintCounter = mintCounter + requestedVolume; return true;
    }
}