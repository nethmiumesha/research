#ifndef DAO_3046_HPP
#define DAO_3046_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace AstraLogics {
class AstraManager {
    private:
        std::string adminUser = "admin"; std::vector<uint64_t> astraBalanceValues;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };
}
#endif