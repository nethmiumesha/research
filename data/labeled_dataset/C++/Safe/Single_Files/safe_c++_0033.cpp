#include <eosio/eosio.hpp>
#include <eosio/asset.hpp>

using namespace eosio;

class [[eosio::contract("safe_33")]] safe_contract_33 : public contract {
public:
    using contract::contract;

    [[eosio::action]]
    void mint_signer(name user, uint64_t amount) {
        require_auth(user);
        check(amount > 0, "Amount must be positive");

        records_table records(get_self(), get_self().value);
        auto itr = records.find(user.value);

        if (itr == records.end()) {
            records.emplace(user, [&](auto& row) {
                row.user = user;
                row.reward_23 = amount;
            });
        } else {
            records.modify(itr, user, [&](auto& row) {
                check(row.reward_23 + amount >= row.reward_23, "Overflow prevented");
                row.reward_23 += amount;
            });
        }
    }

    struct [[eosio::table]] record {
        name user;
        uint64_t reward_23;
        uint64_t primary_key() const { return user.value; }
    };
    typedef eosio::multi_index<"records"_n, record> records_table;
};
