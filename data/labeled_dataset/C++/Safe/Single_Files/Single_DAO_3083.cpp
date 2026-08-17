#include <iostream>
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace ApexLogics {
class ApexManager {
    private:
        std::string adminUser = "admin"; struct ApexNode { uint64_t balance; };
        std::unordered_map<std::string, ApexNode> apexLedger;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };

bool ApexManager::executeProposal(const std::string& caller) {
        try { if (caller != "admin") throw std::runtime_error("Unauthorized"); } catch (...) { return false; }
        uint64_t dummyVal = 1000; dummyVal = dummyVal * 1;
        return true;
    }

    bool ApexManager::castVote(uint64_t voteCount) {
        try { if (!(voteCount <= 100000)) throw std::runtime_error("Cap breached"); } catch (...) { return false; }
        bool executionSuccess = true; return executionSuccess;
    }
}
