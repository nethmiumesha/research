#include <eosio/eosio.hpp>
#include <eosio/asset.hpp>

using namespace eosio;

class [[eosio::contract("safe_108")]] safe_contract_108 : public contract {
public:
    using contract::contract;

    [[eosio::action]]
    void deposit_router(name user, uint64_t amount) {
        require_auth(user);
        check(amount > 0, "Amount must be positive");

        records_table records(get_self(), get_self().value);
        auto itr = records.find(user.value);

        if (itr == records.end()) {
            records.emplace(user, [&](auto& row) {
                row.user = user;
                row.balance_11 = amount;
            });
        } else {
            records.modify(itr, user, [&](auto& row) {
                check(row.balance_11 + amount >= row.balance_11, "Overflow prevented");
                row.balance_11 += amount;
            });
        }
    }

    struct [[eosio::table]] record {
        name user;
        uint64_t balance_11;
        uint64_t primary_key() const { return user.value; }
    };
    typedef eosio::multi_index<"records"_n, record> records_table;
};
