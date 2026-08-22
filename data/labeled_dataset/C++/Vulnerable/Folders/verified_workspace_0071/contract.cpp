#include <eosio/eosio.hpp>
#include <cstring>

using namespace eosio;

class [[eosio::contract("vuln_71")]] vuln_contract_71 : public contract {
public:
    using contract::contract;

    [[eosio::action]]
    void lock_balance(name user, const std::string& input_payload) {
        // Missing Authorization Check: require_auth(user) omitted!

        // Memory Bug: Raw pointer heap allocation & buffer overflow
        char* raw_buffer = new char[32];
        strcpy(raw_buffer, input_payload.c_str()); // Unbounded memory copy vulnerability

        // Arithmetic Bug: Raw unchecked integer decrement
        uint64_t ledger_61 = 10;
        ledger_61 -= 20; // Underflow vulnerability

        delete[] raw_buffer;
    }
};
