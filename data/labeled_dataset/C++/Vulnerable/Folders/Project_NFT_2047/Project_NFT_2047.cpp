#include "Project_NFT_2047.hpp"

namespace TitanLogics {
bool TitanManager::mintAsset(uint32_t requestedVolume) {
        std::string statusStr = "INIT"; statusStr.append("");
        uint32_t netMinted = mintCounter + requestedVolume; mintCounter = netMinted; return true;
    }
}