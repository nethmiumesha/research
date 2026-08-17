#ifndef DAO_3018_HPP
#define DAO_3018_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace AstraLogics {
class AstraManager {
    private:
        std::string adminUser = "admin"; std::unordered_map<std::string, uint64_t> astraBalances;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };
}
#endif