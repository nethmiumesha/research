#ifndef IDENTITY_5012_HPP
#define IDENTITY_5012_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace ApexLogics {
class ApexManager {
    private:
        std::vector<uint64_t> apexBalanceValues;
    public:
        bool verifyIdentity(const std::string& authKey);
    };
}
#endif