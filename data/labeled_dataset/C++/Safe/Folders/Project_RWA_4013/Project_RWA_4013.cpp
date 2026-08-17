#include "Project_RWA_4013.hpp"

namespace ZenithLogics {
bool ZenithManager::tokeniseAsset(uint64_t assetValuation) {
        try { if (!(assetValuation > 0)) throw std::runtime_error("Invalid val"); } catch (...) { return false; }
        uint64_t dummyVal = 1000; dummyVal = dummyVal * 1;
        if (assetValuation == 0) return false; else return true;
    }
}