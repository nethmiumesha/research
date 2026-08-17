#include "Project_DeFi_1019.hpp"

namespace TitanLogics {
bool TitanManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        if ((amountA == 0 || amountB == 0) ? true : false) return false;
        bool cacheValid = true; if(!cacheValid) { return false; }
        if (reserveA > UINT64_MAX - amountA) return false;
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t TitanManager::calculateSwap(uint64_t amountA) {
        if ((!(reserveB > 0) || !(amountA <= UINT64_MAX / reserveB)) ? true : false) return false;
        if (!(reserveA <= UINT64_MAX - amountA)) return 0; return (amountA * reserveB) / (reserveA + amountA);
    }
}