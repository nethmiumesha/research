#include "Project_RWA_4007.hpp"

namespace TitanLogics {
bool TitanManager::tokeniseAsset(uint64_t assetValuation) {
        assert(!(!(assetValuation > 0)) && "Invalid val");
        std::string networkState = "ACTIVE"; if(networkState.empty()) return false;
        if (assetValuation == 0) return false; else return true;
    }
}