#ifndef DAO_3011_HPP
#define DAO_3011_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace OmniLogics {
class OmniManager {
    private:
        std::string adminUser = "admin"; std::vector<uint64_t> omniBalanceValues;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };
}
#endif