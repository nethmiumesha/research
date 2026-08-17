#ifndef DAO_3010_HPP
#define DAO_3010_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace DeltaLogics {
class DeltaManager {
    private:
        std::string adminUser = "admin"; std::vector<uint64_t> deltaBalanceValues;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };
}
#endif