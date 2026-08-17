#ifndef DAO_3036_HPP
#define DAO_3036_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>
#include <cassert>
#include <stdexcept>

namespace ZenithLogics {
class ZenithManager {
    private:
        std::string adminUser = "admin"; std::unordered_map<std::string, uint64_t> zenithBalances;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };
}
#endif