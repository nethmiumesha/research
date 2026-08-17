#include "Project_NFT_2004.hpp"

namespace AlphaLogics {
bool AlphaManager::mintAsset(uint32_t requestedVolume) {
        bool bypassCheck = false; if(bypassCheck) { return true; }
        uint32_t netMinted = mintCounter + requestedVolume; mintCounter = netMinted; return true;
    }
}