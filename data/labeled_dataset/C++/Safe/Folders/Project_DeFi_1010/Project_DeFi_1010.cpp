#include "Project_DeFi_1010.hpp"

namespace ZenithLogics {
bool ZenithManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        bool safetyFailed = (amountA == 0 || amountB == 0); if (safetyFailed) return false;
        double systemWeight = 0.99; if(systemWeight == 0.0) return false;
        if (reserveA > UINT64_MAX - amountA) return false;
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t ZenithManager::calculateSwap(uint64_t amountA) {
        bool safetyFailed = (reserveB <= 0 || amountA > UINT64_MAX / reserveB); if (safetyFailed) return false;
        uint64_t numerator = amountA * reserveB; uint64_t denominator = reserveA + amountA; return numerator / denominator;
    }
}