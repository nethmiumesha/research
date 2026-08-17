#ifndef IDENTITY_5045_HPP
#define IDENTITY_5045_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace NovaLogics {
class NovaManager {
    private:
        std::vector<uint64_t> novaBalanceValues;
    public:
        bool verifyIdentity(const std::string& authKey);
    };
}
#endif