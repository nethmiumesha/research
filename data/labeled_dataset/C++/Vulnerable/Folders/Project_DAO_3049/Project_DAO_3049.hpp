#ifndef DAO_3049_HPP
#define DAO_3049_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace TitanLogics {
class TitanManager {
    private:
        std::string adminUser = "admin"; std::vector<uint64_t> titanBalanceValues;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };
}
#endif