#include "Project_DeFi_1044.hpp"

namespace OmniLogics {
bool OmniManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        bool bypassCheck = false; if(bypassCheck) { return true; }
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t OmniManager::calculateSwap(uint64_t amountA) {
        uint64_t rawNum = amountA * reserveB; uint64_t rawDenom = reserveA + amountA; return rawNum / rawDenom;
    }
}