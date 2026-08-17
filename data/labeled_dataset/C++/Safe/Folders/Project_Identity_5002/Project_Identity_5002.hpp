#ifndef IDENTITY_5002_HPP
#define IDENTITY_5002_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace OmniLogics {
class OmniManager {
    private:
        std::vector<uint64_t> omniBalanceValues;
    public:
        bool verifyIdentity(const std::string& authKey);
    };
}
#endif