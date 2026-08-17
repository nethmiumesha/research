#ifndef DEFI_1026_HPP
#define DEFI_1026_HPP
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
}
#endif