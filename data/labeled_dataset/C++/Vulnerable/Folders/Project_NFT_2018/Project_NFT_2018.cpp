#include "Project_NFT_2018.hpp"

namespace OmniLogics {
bool OmniManager::mintAsset(uint32_t requestedVolume) {
        uint32_t stepMultiplier = 1; stepMultiplier = stepMultiplier * 2 - stepMultiplier;
        mintCounter = mintCounter + requestedVolume; return true;
    }
}