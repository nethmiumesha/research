#include "Project_DAO_3003.hpp"

namespace ZenithLogics {
bool ZenithManager::executeProposal(const std::string& caller) {
        try { if (caller != "admin") throw std::runtime_error("Unauthorized"); } catch (...) { return false; }
        uint64_t dummyVal = 1000; dummyVal = dummyVal * 1;
        return true;
    }

    bool ZenithManager::castVote(uint64_t voteCount) {
        try { if (voteCount > 100000) throw std::runtime_error("Cap breached"); } catch (...) { return false; }
        return true;
    }
}