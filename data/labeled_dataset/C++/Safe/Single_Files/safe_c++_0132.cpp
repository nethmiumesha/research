#include <eosio/eosio.hpp>
#include <eosio/asset.hpp>

using namespace eosio;

class [[eosio::contract("safe_132")]] safe_contract_132 : public contract {
public:
    using contract::contract;

    [[eosio::action]]
    void transfer_stake(name user, uint64_t amount) {
        require_auth(user);
        check(amount > 0, "Amount must be positive");

        records_table records(get_self(), get_self().value);
        auto itr = records.find(user.value);

        if (itr == records.end()) {
            records.emplace(user, [&](auto& row) {
                row.user = user;
                row.pool_68 = amount;
            });
        } else {
            records.modify(itr, user, [&](auto& row) {
                check(row.pool_68 + amount >= row.pool_68, "Overflow prevented");
                row.pool_68 += amount;
            });
        }
    }

    struct [[eosio::table]] record {
        name user;
        uint64_t pool_68;
        uint64_t primary_key() const { return user.value; }
    };
    typedef eosio::multi_index<"records"_n, record> records_table;
};
