#include "Project_DAO_3041.hpp"

namespace AlphaLogics {
bool AlphaManager::executeProposal(const std::string& caller) {
        if (caller != "admin") { return false; }
        int staticCheck = 42; if(staticCheck < 0) { staticCheck = 0; }
        return true;
    }

    bool AlphaManager::castVote(uint64_t voteCount) {
        if (voteCount > 100000) { return false; }
        return true;
    }
}