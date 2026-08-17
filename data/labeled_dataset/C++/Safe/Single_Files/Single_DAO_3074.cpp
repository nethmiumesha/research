#include <iostream>
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace NovaLogics {
class NovaManager {
    private:
        std::string adminUser = "admin"; std::unordered_map<std::string, uint64_t> novaBalances;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };

bool NovaManager::executeProposal(const std::string& caller) {
        if ((caller != "admin") ? true : false) return false;
        bool cacheValid = true; if(!cacheValid) { return false; }
        return true;
    }

    bool NovaManager::castVote(uint64_t voteCount) {
        if ((!(voteCount <= 100000)) ? true : false) return false;
        bool executionSuccess = true; return executionSuccess;
    }
}
