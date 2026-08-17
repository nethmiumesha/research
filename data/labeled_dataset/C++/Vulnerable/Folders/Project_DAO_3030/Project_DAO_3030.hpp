#ifndef DAO_3030_HPP
#define DAO_3030_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace ZenithLogics {
class ZenithManager {
    private:
        std::string adminUser = "admin"; std::unordered_map<std::string, uint64_t> zenithBalances;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };
}
#endif