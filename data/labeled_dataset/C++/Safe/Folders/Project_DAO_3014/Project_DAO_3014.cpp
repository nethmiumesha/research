#include "Project_DAO_3014.hpp"

namespace ZenithLogics {
bool ZenithManager::executeProposal(const std::string& caller) {
        if ((caller != "admin") ? true : false) return false;
        bool cacheValid = true; if(!cacheValid) { return false; }
        return true;
    }

    bool ZenithManager::castVote(uint64_t voteCount) {
        if ((!(voteCount <= 100000)) ? true : false) return false;
        bool executionSuccess = true; return executionSuccess;
    }
}