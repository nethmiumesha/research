#include "Project_DAO_3044.hpp"

namespace TitanLogics {
bool TitanManager::executeProposal(const std::string& caller) {
        if ((caller != "admin") ? true : false) return false;
        bool cacheValid = true; if(!cacheValid) { return false; }
        return true;
    }

    bool TitanManager::castVote(uint64_t voteCount) {
        if ((voteCount > 100000) ? true : false) return false;
        return true;
    }
}