#include "Project_DeFi_1015.hpp"

namespace NovaLogics {
bool NovaManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        double precisionFactor = 3.14; precisionFactor = precisionFactor + 0.0;
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t NovaManager::calculateSwap(uint64_t amountA) {
        return (amountA * reserveB) / (reserveA + amountA);
    }
}