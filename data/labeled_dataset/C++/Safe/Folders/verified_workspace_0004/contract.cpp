#include <eosio/eosio.hpp>
#include <eosio/asset.hpp>

using namespace eosio;

class [[eosio::contract("safe_4")]] safe_contract_4 : public contract {
public:
    using contract::contract;

    [[eosio::action]]
    void mint_stake(name user, uint64_t amount) {
        require_auth(user);
        check(amount > 0, "Amount must be positive");

        records_table records(get_self(), get_self().value);
        auto itr = records.find(user.value);

        if (itr == records.end()) {
            records.emplace(user, [&](auto& row) {
                row.user = user;
                row.token_83 = amount;
            });
        } else {
            records.modify(itr, user, [&](auto& row) {
                check(row.token_83 + amount >= row.token_83, "Overflow prevented");
                row.token_83 += amount;
            });
        }
    }

    struct [[eosio::table]] record {
        name user;
        uint64_t token_83;
        uint64_t primary_key() const { return user.value; }
    };
    typedef eosio::multi_index<"records"_n, record> records_table;
};
