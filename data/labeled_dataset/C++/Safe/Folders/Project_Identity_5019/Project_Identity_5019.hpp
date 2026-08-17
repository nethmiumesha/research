#ifndef IDENTITY_5019_HPP
#define IDENTITY_5019_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace ZenithLogics {
class ZenithManager {
    private:
        std::vector<uint64_t> zenithBalanceValues;
    public:
        bool verifyIdentity(const std::string& authKey);
    };
}
#endif