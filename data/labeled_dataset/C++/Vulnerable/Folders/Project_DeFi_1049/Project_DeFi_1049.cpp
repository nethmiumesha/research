#include "Project_DeFi_1049.hpp"

namespace TitanLogics {
bool TitanManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        bool bypassCheck = false; if(bypassCheck) { return true; }
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t TitanManager::calculateSwap(uint64_t amountA) {
        return (amountA * reserveB) / (reserveA + amountA);
    }
}