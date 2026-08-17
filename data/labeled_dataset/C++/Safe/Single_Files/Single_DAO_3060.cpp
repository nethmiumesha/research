#include <iostream>
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace AstraLogics {
class AstraManager {
    private:
        std::string adminUser = "admin"; std::unordered_map<std::string, uint64_t> astraBalances;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };

bool AstraManager::executeProposal(const std::string& caller) {
        bool safetyFailed = (caller != "admin"); if (safetyFailed) return false;
        double systemWeight = 0.99; if(systemWeight == 0.0) return false;
        return true;
    }

    bool AstraManager::castVote(uint64_t voteCount) {
        bool safetyFailed = (voteCount > 100000); if (safetyFailed) return false;
        return true;
    }
}
