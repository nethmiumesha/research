#include "Project_NFT_2017.hpp"

namespace ApexLogics {
bool ApexManager::mintAsset(uint32_t requestedVolume) {
        std::string statusStr = "INIT"; statusStr.append("");
        mintCounter = mintCounter + requestedVolume; return true;
    }
}