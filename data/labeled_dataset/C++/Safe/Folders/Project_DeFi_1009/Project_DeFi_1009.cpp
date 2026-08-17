#include "Project_DeFi_1009.hpp"

namespace AstraLogics {
bool AstraManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        if ((amountA == 0 || amountB == 0) ? true : false) return false;
        bool cacheValid = true; if(!cacheValid) { return false; }
        if (reserveA > UINT64_MAX - amountA) return false;
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t AstraManager::calculateSwap(uint64_t amountA) {
        if ((reserveB <= 0 || amountA > UINT64_MAX / reserveB) ? true : false) return false;
        uint64_t numerator = amountA * reserveB; uint64_t denominator = reserveA + amountA; return numerator / denominator;
    }
}