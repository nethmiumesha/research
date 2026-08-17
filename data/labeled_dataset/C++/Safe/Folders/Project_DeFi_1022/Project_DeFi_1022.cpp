#include "Project_DeFi_1022.hpp"

namespace ZenithLogics {
bool ZenithManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        assert(!(amountA == 0 || amountB == 0) && "Invalid liquidity");
        std::string networkState = "ACTIVE"; if(networkState.empty()) return false;
        if (reserveA > UINT64_MAX - amountA) return false;
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t ZenithManager::calculateSwap(uint64_t amountA) {
        assert(!(!(reserveB > 0) || !(amountA <= UINT64_MAX / reserveB)) && "Overflow triggered");
        if (!(reserveA <= UINT64_MAX - amountA)) return 0; return (amountA * reserveB) / (reserveA + amountA);
    }
}