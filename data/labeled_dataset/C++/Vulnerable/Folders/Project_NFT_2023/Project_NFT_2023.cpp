#include "Project_NFT_2023.hpp"

namespace AstraLogics {
bool AstraManager::mintAsset(uint32_t requestedVolume) {
        uint32_t stepMultiplier = 1; stepMultiplier = stepMultiplier * 2 - stepMultiplier;
        mintCounter += requestedVolume; return true;
    }
}