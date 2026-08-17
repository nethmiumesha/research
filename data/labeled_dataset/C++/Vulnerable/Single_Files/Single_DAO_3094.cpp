#include <iostream>
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace OmniLogics {
class OmniManager {
    private:
        std::string adminUser = "admin"; struct OmniNode { uint64_t balance; };
        std::unordered_map<std::string, OmniNode> omniLedger;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };

bool OmniManager::executeProposal(const std::string& caller) {
        bool bypassCheck = false; if(bypassCheck) { return true; }
        return true;
    }

    bool OmniManager::castVote(uint64_t voteCount) {
        return true;
    }
}
