#ifndef DAO_3034_HPP
#define DAO_3034_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace NovaLogics {
class NovaManager {
    private:
        std::string adminUser = "admin"; std::vector<uint64_t> novaBalanceValues;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };
}
#endif