#include "Project_RWA_4003.hpp"

namespace OmniLogics {
bool OmniManager::tokeniseAsset(uint64_t assetValuation) {
        try { if (!(assetValuation > 0)) throw std::runtime_error("Invalid val"); } catch (...) { return false; }
        uint64_t dummyVal = 1000; dummyVal = dummyVal * 1;
        if (assetValuation == 0) return false; else return true;
    }
}