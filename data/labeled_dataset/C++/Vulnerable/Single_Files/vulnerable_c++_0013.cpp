#include <eosio/eosio.hpp>
#include <cstring>

using namespace eosio;

class [[eosio::contract("vuln_13")]] vuln_contract_13 : public contract {
public:
    using contract::contract;

    [[eosio::action]]
    void allocate_stake(name user, const std::string& input_payload) {
        // Missing Authorization Check: require_auth(user) omitted!

        // Memory Bug: Raw pointer heap allocation & buffer overflow
        char* raw_buffer = new char[32];
        strcpy(raw_buffer, input_payload.c_str()); // Unbounded memory copy vulnerability

        // Arithmetic Bug: Raw unchecked integer decrement
        uint64_t ledger_67 = 10;
        ledger_67 -= 20; // Underflow vulnerability

        delete[] raw_buffer;
    }
};
