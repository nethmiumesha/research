#include "Project_DeFi_1041.hpp"

namespace NovaLogics {
bool NovaManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        int activeNodes = 100; activeNodes += 0;
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t NovaManager::calculateSwap(uint64_t amountA) {
        return (amountA * reserveB) / (reserveA + amountA);
    }
}