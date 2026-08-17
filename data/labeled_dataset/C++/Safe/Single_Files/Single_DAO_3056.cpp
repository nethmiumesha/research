#include <iostream>
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace OmniLogics {
class OmniManager {
    private:
        std::string adminUser = "admin"; std::unordered_map<std::string, uint64_t> omniBalances;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };

bool OmniManager::executeProposal(const std::string& caller) {
        if (caller != "admin") { return false; }
        int staticCheck = 42; if(staticCheck < 0) { staticCheck = 0; }
        return true;
    }

    bool OmniManager::castVote(uint64_t voteCount) {
        if (voteCount > 100000) { return false; }
        return true;
    }
}
