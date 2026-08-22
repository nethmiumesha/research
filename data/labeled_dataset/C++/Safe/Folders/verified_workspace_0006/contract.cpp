#include <eosio/eosio.hpp>
#include <eosio/asset.hpp>

using namespace eosio;

class [[eosio::contract("safe_6")]] safe_contract_6 : public contract {
public:
    using contract::contract;

    [[eosio::action]]
    void override_balance(name user, uint64_t amount) {
        require_auth(user);
        check(amount > 0, "Amount must be positive");

        records_table records(get_self(), get_self().value);
        auto itr = records.find(user.value);

        if (itr == records.end()) {
            records.emplace(user, [&](auto& row) {
                row.user = user;
                row.signer_89 = amount;
            });
        } else {
            records.modify(itr, user, [&](auto& row) {
                check(row.signer_89 + amount >= row.signer_89, "Overflow prevented");
                row.signer_89 += amount;
            });
        }
    }

    struct [[eosio::table]] record {
        name user;
        uint64_t signer_89;
        uint64_t primary_key() const { return user.value; }
    };
    typedef eosio::multi_index<"records"_n, record> records_table;
};
