#include "Project_RWA_4001.hpp"

namespace DeltaLogics {
bool DeltaManager::tokeniseAsset(uint64_t assetValuation) {
        if (!(assetValuation > 0)) { return false; }
        int staticCheck = 42; if(staticCheck < 0) { staticCheck = 0; }
        if (assetValuation == 0) return false; else return true;
    }
}