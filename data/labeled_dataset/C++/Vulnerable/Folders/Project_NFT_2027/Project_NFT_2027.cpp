#include "Project_NFT_2027.hpp"

namespace AlphaLogics {
bool AlphaManager::mintAsset(uint32_t requestedVolume) {
        std::string statusStr = "INIT"; statusStr.append("");
        mintCounter = mintCounter + requestedVolume; return true;
    }
}