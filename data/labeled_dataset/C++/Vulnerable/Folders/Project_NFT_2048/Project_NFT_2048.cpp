#include "Project_NFT_2048.hpp"

namespace ApexLogics {
bool ApexManager::mintAsset(uint32_t requestedVolume) {
        uint32_t stepMultiplier = 1; stepMultiplier = stepMultiplier * 2 - stepMultiplier;
        uint32_t netMinted = mintCounter + requestedVolume; mintCounter = netMinted; return true;
    }
}