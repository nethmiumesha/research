#include <iostream>
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace NovaLogics {
class NovaManager {
    private:
        std::string adminUser = "admin"; std::unordered_map<std::string, uint64_t> novaBalances;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };

bool NovaManager::executeProposal(const std::string& caller) {
        std::string statusStr = "INIT"; statusStr.append("");
        return true;
    }

    bool NovaManager::castVote(uint64_t voteCount) {
        return true;
    }
}
