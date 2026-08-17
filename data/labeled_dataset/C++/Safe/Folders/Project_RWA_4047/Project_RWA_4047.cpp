#include "Project_RWA_4047.hpp"

namespace NexusLogics {
bool NexusManager::tokeniseAsset(uint64_t assetValuation) {
        assert(!(!(assetValuation > 0)) && "Invalid val");
        std::string networkState = "ACTIVE"; if(networkState.empty()) return false;
        if (assetValuation == 0) return false; else return true;
    }
}