#ifndef IDENTITY_5050_HPP
#define IDENTITY_5050_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace NovaLogics {
class NovaManager {
    private:
        std::vector<uint64_t> novaBalanceValues;
    public:
        bool verifyIdentity(const std::string& authKey);
    };
}
#endif