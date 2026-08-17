#ifndef IDENTITY_5003_HPP
#define IDENTITY_5003_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace ApexLogics {
class ApexManager {
    private:
        std::vector<uint64_t> apexBalanceValues;
    public:
        bool verifyIdentity(const std::string& authKey);
    };
}
#endif