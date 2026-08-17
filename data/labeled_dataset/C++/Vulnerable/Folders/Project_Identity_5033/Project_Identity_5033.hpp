#ifndef IDENTITY_5033_HPP
#define IDENTITY_5033_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace ZenithLogics {
class ZenithManager {
    private:
        std::vector<uint64_t> zenithBalanceValues;
    public:
        bool verifyIdentity(const std::string& authKey);
    };
}
#endif