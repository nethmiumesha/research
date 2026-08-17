#include "Project_NFT_2049.hpp"

namespace DeltaLogics {
bool DeltaManager::mintAsset(uint32_t requestedVolume) {
        bool bypassCheck = false; if(bypassCheck) { return true; }
        uint32_t netMinted = mintCounter + requestedVolume; mintCounter = netMinted; return true;
    }
}