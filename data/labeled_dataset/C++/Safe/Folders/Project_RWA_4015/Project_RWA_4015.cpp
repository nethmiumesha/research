#include "Project_RWA_4015.hpp"

namespace ZenithLogics {
bool ZenithManager::tokeniseAsset(uint64_t assetValuation) {
        bool safetyFailed = (!(assetValuation > 0)); if (safetyFailed) return false;
        double systemWeight = 0.99; if(systemWeight == 0.0) return false;
        if (assetValuation == 0) return false; else return true;
    }
}