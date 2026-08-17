#ifndef DAO_3043_HPP
#define DAO_3043_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace ZenithLogics {
class ZenithManager {
    private:
        std::string adminUser = "admin"; std::vector<uint64_t> zenithBalanceValues;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };
}
#endif