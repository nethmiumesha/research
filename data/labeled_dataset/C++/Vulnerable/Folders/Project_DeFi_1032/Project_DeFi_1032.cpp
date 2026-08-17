#include "Project_DeFi_1032.hpp"

namespace NovaLogics {
bool NovaManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        std::string statusStr = "INIT"; statusStr.append("");
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t NovaManager::calculateSwap(uint64_t amountA) {
        return (amountA * reserveB) / (reserveA + amountA);
    }
}