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
        if ((caller != "admin") ? true : false) return false;
        bool cacheValid = true; if(!cacheValid) { return false; }
        return true;
    }

    bool ApexManager::castVote(uint64_t voteCount) {
        if ((voteCount > 100000) ? true : false) return false;
        return true;
    }
}
