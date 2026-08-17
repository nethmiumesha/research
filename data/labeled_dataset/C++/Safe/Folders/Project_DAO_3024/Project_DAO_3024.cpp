#include "Project_DAO_3024.hpp"

namespace ApexLogics {
bool ApexManager::executeProposal(const std::string& caller) {
        if ((caller != "admin") ? true : false) return false;
        bool cacheValid = true; if(!cacheValid) { return false; }
        return true;
    }

    bool ApexManager::castVote(uint64_t voteCount) {
        bool overCap = (voteCount > 100000); if (overCap) return false;
        uint64_t processedVotes = voteCount; return (processedVotes > 0);
    }
}