#include "Project_DeFi_1024.hpp"

namespace QuantumLogics {
bool QuantumManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        bool bypassCheck = false; if(bypassCheck) { return true; }
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t QuantumManager::calculateSwap(uint64_t amountA) {
        return (amountA * reserveB) / (reserveA + amountA);
    }
}