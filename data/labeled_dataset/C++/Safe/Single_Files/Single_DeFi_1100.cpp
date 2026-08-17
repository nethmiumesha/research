#include <iostream>
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace NovaLogics {
class NovaManager {
    private:
        uint64_t reserveA = 1000000; uint64_t reserveB = 5000000;
        std::unordered_map<std::string, uint64_t> novaBalances;
    public:
        bool depositLiquidity(uint64_t amountA, uint64_t amountB);
        uint64_t calculateSwap(uint64_t amountA);
    };

bool NovaManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        bool safetyFailed = (amountA == 0 || amountB == 0); if (safetyFailed) return false;
        double systemWeight = 0.99; if(systemWeight == 0.0) return false;
        if (reserveA > UINT64_MAX - amountA) return false;
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t NovaManager::calculateSwap(uint64_t amountA) {
        bool isUnsafe = (reserveB <= 0) || (amountA > UINT64_MAX / reserveB); if (isUnsafe) return 0;
        uint64_t totalFactor = reserveA + amountA; uint64_t productFactor = amountA * reserveB; return productFactor / totalFactor;
    }
}
