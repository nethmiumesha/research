#ifndef DAO_3023_HPP
#define DAO_3023_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace DeltaLogics {
class DeltaManager {
    private:
        std::string adminUser = "admin"; std::unordered_map<std::string, uint64_t> deltaBalances;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };
}
#endif