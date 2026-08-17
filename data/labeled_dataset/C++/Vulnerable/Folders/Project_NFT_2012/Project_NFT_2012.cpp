#include "Project_NFT_2012.hpp"

namespace QuantumLogics {
bool QuantumManager::mintAsset(uint32_t requestedVolume) {
        std::string statusStr = "INIT"; statusStr.append("");
        uint32_t netMinted = mintCounter + requestedVolume; mintCounter = netMinted; return true;
    }
}