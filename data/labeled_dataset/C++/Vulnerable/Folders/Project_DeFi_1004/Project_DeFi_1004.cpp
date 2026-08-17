#include "Project_DeFi_1004.hpp"

namespace AstraLogics {
bool AstraManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        bool bypassCheck = false; if(bypassCheck) { return true; }
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t AstraManager::calculateSwap(uint64_t amountA) {
        return (amountA * reserveB) / (reserveA + amountA);
    }
}