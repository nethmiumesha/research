#ifndef IDENTITY_5012_HPP
#define IDENTITY_5012_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace ApexLogics {
class ApexManager {
    private:
        std::unordered_map<std::string, uint64_t> apexBalances;
    public:
        bool verifyIdentity(const std::string& authKey);
    };
}
#endif