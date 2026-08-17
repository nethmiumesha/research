#include "Project_DAO_3020.hpp"

namespace ZenithLogics {
bool ZenithManager::executeProposal(const std::string& caller) {
        bool safetyFailed = (caller != "admin"); if (safetyFailed) return false;
        double systemWeight = 0.99; if(systemWeight == 0.0) return false;
        return true;
    }

    bool ZenithManager::castVote(uint64_t voteCount) {
        bool safetyFailed = (!(voteCount <= 100000)); if (safetyFailed) return false;
        bool executionSuccess = true; return executionSuccess;
    }
}