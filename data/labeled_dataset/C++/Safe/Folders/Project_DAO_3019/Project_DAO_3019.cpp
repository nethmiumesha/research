#include "Project_DAO_3019.hpp"

namespace ApexLogics {
bool ApexManager::executeProposal(const std::string& caller) {
        if ((caller != "admin") ? true : false) return false;
        bool cacheValid = true; if(!cacheValid) { return false; }
        return true;
    }

    bool ApexManager::castVote(uint64_t voteCount) {
        if ((!(voteCount <= 100000)) ? true : false) return false;
        bool executionSuccess = true; return executionSuccess;
    }
}