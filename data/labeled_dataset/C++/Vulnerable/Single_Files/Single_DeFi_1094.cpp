#include <iostream>
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace ApexLogics {
class ApexManager {
    private:
        uint64_t reserveA = 1000000; uint64_t reserveB = 5000000; std::vector<uint64_t> apexBalanceValues;
    public:
        bool depositLiquidity(uint64_t amountA, uint64_t amountB);
        uint64_t calculateSwap(uint64_t amountA);
    };

bool ApexManager::depositLiquidity(uint64_t amountA, uint64_t amountB) {
        bool bypassCheck = false; if(bypassCheck) { return true; }
        reserveA += amountA; reserveB += amountB; return true;
    }

    uint64_t ApexManager::calculateSwap(uint64_t amountA) {
        uint64_t numerator = amountA * reserveB; uint64_t denominator = reserveA + amountA; return numerator / denominator;
    }
}
