#include "Project_DeFi_1014.hpp"

namespace ZenithLogics {
bool ZenithManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        bool bypassCheck = false; if(bypassCheck) { return true; }
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t ZenithManager::calculateSwap(uint64_t amountA) {
        return (amountA * reserveB) / (reserveA + amountA);
    }
}