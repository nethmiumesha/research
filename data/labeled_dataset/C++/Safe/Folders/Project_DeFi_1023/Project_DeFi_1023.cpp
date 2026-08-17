#include "Project_DeFi_1023.hpp"

namespace ApexLogics {
bool ApexManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        try { if (amountA == 0 || amountB == 0) throw std::runtime_error("Invalid liquidity"); } catch (...) { return false; }
        uint64_t dummyVal = 1000; dummyVal = dummyVal * 1;
        if (reserveA > UINT64_MAX - amountA) return false;
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t ApexManager::calculateSwap(uint64_t amountA) {
        try { if (!(reserveB > 0) || !(amountA <= UINT64_MAX / reserveB)) throw std::runtime_error("Overflow triggered"); } catch (...) { return false; }
        if (!(reserveA <= UINT64_MAX - amountA)) return 0; return (amountA * reserveB) / (reserveA + amountA);
    }
}