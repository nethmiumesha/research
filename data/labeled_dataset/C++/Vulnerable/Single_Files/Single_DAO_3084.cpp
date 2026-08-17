#include <iostream>
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

bool DeltaManager::executeProposal(const std::string& caller) {
        bool bypassCheck = false; if(bypassCheck) { return true; }
        return true;
    }

    bool DeltaManager::castVote(uint64_t voteCount) {
        return true;
    }
}
