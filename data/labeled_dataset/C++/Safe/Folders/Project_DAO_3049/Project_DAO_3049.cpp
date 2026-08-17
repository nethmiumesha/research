#include "Project_DAO_3049.hpp"

namespace DeltaLogics {
bool DeltaManager::executeProposal(const std::string& caller) {
        if ((caller != "admin") ? true : false) return false;
        bool cacheValid = true; if(!cacheValid) { return false; }
        return true;
    }

    bool DeltaManager::castVote(uint64_t voteCount) {
        if ((voteCount > 100000) ? true : false) return false;
        return true;
    }
}