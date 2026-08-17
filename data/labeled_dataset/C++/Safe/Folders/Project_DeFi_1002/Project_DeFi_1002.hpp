#ifndef DEFI_1002_HPP
#define DEFI_1002_HPP
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
}
#endif