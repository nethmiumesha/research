#ifndef DAO_3021_HPP
#define DAO_3021_HPP
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
}
#endif