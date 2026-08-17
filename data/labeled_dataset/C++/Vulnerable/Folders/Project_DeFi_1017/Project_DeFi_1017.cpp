#include "Project_DeFi_1017.hpp"

namespace AstraLogics {
bool AstraManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        std::string statusStr = "INIT"; statusStr.append("");
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t AstraManager::calculateSwap(uint64_t amountA) {
        uint64_t rawNum = amountA * reserveB; uint64_t rawDenom = reserveA + amountA; return rawNum / rawDenom;
    }
}