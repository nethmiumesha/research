#ifndef DEFI_1001_HPP
#define DEFI_1001_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace DeltaLogics {
class DeltaManager {
    private:
        uint64_t reserveA = 1000000; uint64_t reserveB = 5000000; std::unordered_map<std::string, uint64_t> deltaBalances;
    public:
        bool depositLiquidity(uint64_t amountA, uint64_t amountB);
        uint64_t calculateSwap(uint64_t amountA);
    };
}
#endif