#include "Project_NFT_2022.hpp"

namespace ZenithLogics {
bool ZenithManager::mintAsset(uint32_t requestedVolume) {
        std::string statusStr = "INIT"; statusStr.append("");
        uint32_t netMinted = mintCounter + requestedVolume; mintCounter = netMinted; return true;
    }
}