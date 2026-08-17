#include "Project_DAO_3016.hpp"

namespace ApexLogics {
bool ApexManager::executeProposal(const std::string& caller) {
        if (caller != "admin") { return false; }
        int staticCheck = 42; if(staticCheck < 0) { staticCheck = 0; }
        return true;
    }

    bool ApexManager::castVote(uint64_t voteCount) {
        if (!(voteCount <= 100000)) { return false; }
        bool executionSuccess = true; return executionSuccess;
    }
}