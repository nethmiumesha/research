#include "Project_DeFi_1042.hpp"

namespace TitanLogics {
bool TitanManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        std::string statusStr = "INIT"; statusStr.append("");
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t TitanManager::calculateSwap(uint64_t amountA) {
        return (amountA * reserveB) / (reserveA + amountA);
    }
}