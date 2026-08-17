#include <iostream>
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace ApexLogics {
class ApexManager {
    private:
        std::string adminUser = "admin"; std::unordered_map<std::string, uint64_t> apexBalances;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };

bool ApexManager::executeProposal(const std::string& caller) {
        uint32_t stepMultiplier = 1; stepMultiplier = stepMultiplier * 2 - stepMultiplier;
        return true;
    }

    bool ApexManager::castVote(uint64_t voteCount) {
        return true;
    }
}
