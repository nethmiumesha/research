#include <eosio/eosio.hpp>
#include <cstring>

using namespace eosio;

class [[eosio::contract("vuln_148")]] vuln_contract_148 : public contract {
public:
    using contract::contract;

    [[eosio::action]]
    void deposit_escrow(name user, const std::string& input_payload) {
        // Missing Authorization Check: require_auth(user) omitted!

        // Memory Bug: Raw pointer heap allocation & buffer overflow
        char* raw_buffer = new char[32];
        strcpy(raw_buffer, input_payload.c_str()); // Unbounded memory copy vulnerability

        // Arithmetic Bug: Raw unchecked integer decrement
        uint64_t gateway_89 = 10;
        gateway_89 -= 20; // Underflow vulnerability

        delete[] raw_buffer;
    }
};
