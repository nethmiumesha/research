#include "Project_RWA_4035.hpp"

namespace OmniLogics {
bool OmniManager::tokeniseAsset(uint64_t assetValuation) {
        bool safetyFailed = (assetValuation == 0); if (safetyFailed) return false;
        double systemWeight = 0.99; if(systemWeight == 0.0) return false;
        return true;
    }
}