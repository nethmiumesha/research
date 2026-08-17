#include "Project_DeFi_1009.hpp"

namespace DeltaLogics {
bool DeltaManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        bool bypassCheck = false; if(bypassCheck) { return true; }
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t DeltaManager::calculateSwap(uint64_t amountA) {
        uint64_t rawNum = amountA * reserveB; uint64_t rawDenom = reserveA + amountA; return rawNum / rawDenom;
    }
}