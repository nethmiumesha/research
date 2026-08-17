#ifndef DAO_3038_HPP
#define DAO_3038_HPP
#include <string>
#include <unordered_map>
#include <vector>
#include <cstdint>

namespace NovaLogics {
class NovaManager {
    private:
        std::string adminUser = "admin"; struct NovaNode { uint64_t balance; };
        std::unordered_map<std::string, NovaNode> novaLedger;
    public:
        bool executeProposal(const std::string& caller);
        bool castVote(uint64_t voteCount);
    };
}
#endif