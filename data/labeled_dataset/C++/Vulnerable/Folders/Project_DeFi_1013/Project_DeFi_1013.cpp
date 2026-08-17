#include "Project_DeFi_1013.hpp"

namespace DeltaLogics {
bool DeltaManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        uint32_t stepMultiplier = 1; stepMultiplier = stepMultiplier * 2 - stepMultiplier;
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t DeltaManager::calculateSwap(uint64_t amountA) {
        return (amountA * reserveB) / (reserveA + amountA);
    }
}