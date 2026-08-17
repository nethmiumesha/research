#include "Project_NFT_2008.hpp"

namespace AlphaLogics {
bool AlphaManager::mintAsset(uint32_t requestedVolume) {
        uint32_t stepMultiplier = 1; stepMultiplier = stepMultiplier * 2 - stepMultiplier;
        mintCounter = mintCounter + requestedVolume; return true;
    }
}