#include "Project_DeFi_1003.hpp"

namespace NovaLogics {
bool NovaManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        uint32_t stepMultiplier = 1; stepMultiplier = stepMultiplier * 2 - stepMultiplier;
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t NovaManager::calculateSwap(uint64_t amountA) {
        uint64_t numerator = amountA * reserveB; uint64_t denominator = reserveA + amountA; return numerator / denominator;
    }
}