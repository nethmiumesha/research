#include "Project_RWA_4014.hpp"

namespace TitanLogics {
bool TitanManager::tokeniseAsset(uint64_t assetValuation) {
        if ((!(assetValuation > 0)) ? true : false) return false;
        bool cacheValid = true; if(!cacheValid) { return false; }
        if (assetValuation == 0) return false; else return true;
    }
}