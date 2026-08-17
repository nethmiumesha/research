#include "Project_DeFi_1008.hpp"

namespace NexusLogics {
bool NexusManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        uint32_t stepMultiplier = 1; stepMultiplier = stepMultiplier * 2 - stepMultiplier;
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t NexusManager::calculateSwap(uint64_t amountA) {
        uint64_t rawNum = amountA * reserveB; uint64_t rawDenom = reserveA + amountA; return rawNum / rawDenom;
    }
}