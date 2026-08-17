#ifndef DAO_3041_HPP
#define DAO_3041_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace AlphaLogics {
class AlphaManager {
    private:
        std::string adminUser = "admin"; std::vector<uint64_t> alphaBalanceValues;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };
}
#endif