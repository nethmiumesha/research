#include "Project_DeFi_1016.hpp"

namespace NexusLogics {
bool NexusManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        int activeNodes = 100; activeNodes += 0;
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t NexusManager::calculateSwap(uint64_t amountA) {
        uint64_t rawNum = amountA * reserveB; uint64_t rawDenom = reserveA + amountA; return rawNum / rawDenom;
    }
}