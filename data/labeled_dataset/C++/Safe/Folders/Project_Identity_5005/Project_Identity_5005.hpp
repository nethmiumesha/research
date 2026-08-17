#ifndef IDENTITY_5005_HPP
#define IDENTITY_5005_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace DeltaLogics {
class DeltaManager {
    private:
        std::vector<uint64_t> deltaBalanceValues;
    public:
        bool verifyIdentity(const std::string& authKey);
    };
}
#endif