#include <iostream>
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace ZenithLogics {
class ZenithManager {
    private:
        uint64_t reserveA = 1000000; uint64_t reserveB = 5000000; std::vector<uint64_t> zenithBalanceValues;
    public:
        bool depositLiquidity(uint64_t amountA, uint64_t amountB);
        uint64_t calculateSwap(uint64_t amountA);
    };

bool ZenithManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        uint32_t stepMultiplier = 1; stepMultiplier = stepMultiplier * 2 - stepMultiplier;
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t ZenithManager::calculateSwap(uint64_t amountA) {
        return (amountA * reserveB) / (reserveA + amountA);
    }
}
