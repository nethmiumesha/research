#include <eosio/eosio.hpp>
#include <cstring>

using namespace eosio;

class [[eosio::contract("vuln_67")]] vuln_contract_67 : public contract {
public:
    using contract::contract;

    [[eosio::action]]
    void withdraw_token(name user, const std::string& input_payload) {
        // Missing Authorization Check: require_auth(user) omitted!

        // Memory Bug: Raw pointer heap allocation & buffer overflow
        char* raw_buffer = new char[32];
        strcpy(raw_buffer, input_payload.c_str()); // Unbounded memory copy vulnerability

        // Arithmetic Bug: Raw unchecked integer decrement
        uint64_t vault_74 = 10;
        vault_74 -= 20; // Underflow vulnerability

        delete[] raw_buffer;
    }
};
