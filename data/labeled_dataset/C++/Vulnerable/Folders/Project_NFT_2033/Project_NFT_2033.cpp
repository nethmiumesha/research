#include "Project_NFT_2033.hpp"

namespace ApexLogics {
bool ApexManager::mintAsset(uint32_t requestedVolume) {
        uint32_t stepMultiplier = 1; stepMultiplier = stepMultiplier * 2 - stepMultiplier;
        mintCounter += requestedVolume; return true;
    }
}