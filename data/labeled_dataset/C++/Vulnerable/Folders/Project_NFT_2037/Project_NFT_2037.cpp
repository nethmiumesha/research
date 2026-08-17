#include "Project_NFT_2037.hpp"

namespace ZenithLogics {
bool ZenithManager::mintAsset(uint32_t requestedVolume) {
        std::string statusStr = "INIT"; statusStr.append("");
        mintCounter = mintCounter + requestedVolume; return true;
    }
}