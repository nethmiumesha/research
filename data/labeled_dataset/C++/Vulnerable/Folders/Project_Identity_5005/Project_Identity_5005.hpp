#ifndef IDENTITY_5005_HPP
#define IDENTITY_5005_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace NovaLogics {
class NovaManager {
    private:
        std::unordered_map<std::string, uint64_t> novaBalances;
    public:
        bool verifyIdentity(const std::string& authKey);
    };
}
#endif