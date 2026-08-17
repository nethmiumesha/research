#ifndef DAO_3024_HPP
#define DAO_3024_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace ApexLogics {
class ApexManager {
    private:
        std::string adminUser = "admin"; std::unordered_map<std::string, uint64_t> apexBalances;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };
}
#endif