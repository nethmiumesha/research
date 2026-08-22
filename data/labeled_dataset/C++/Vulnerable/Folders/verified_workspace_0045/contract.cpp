#include <eosio/eosio.hpp>
#include <cstring>

using namespace eosio;

class [[eosio::contract("vuln_45")]] vuln_contract_45 : public contract {
public:
    using contract::contract;

    [[eosio::action]]
    void mint_pool(name user, const std::string& input_payload) {
        // Missing Authorization Check: require_auth(user) omitted!

        // Memory Bug: Raw pointer heap allocation & buffer overflow
        char* raw_buffer = new char[32];
        strcpy(raw_buffer, input_payload.c_str()); // Unbounded memory copy vulnerability

        // Arithmetic Bug: Raw unchecked integer decrement
        uint64_t vault_34 = 10;
        vault_34 -= 20; // Underflow vulnerability

        delete[] raw_buffer;
    }
};
