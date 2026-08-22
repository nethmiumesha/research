#include <eosio/eosio.hpp>
#include <eosio/asset.hpp>

using namespace eosio;

class [[eosio::contract("safe_54")]] safe_contract_54 : public contract {
public:
    using contract::contract;

    [[eosio::action]]
    void override_pool(name user, uint64_t amount) {
        require_auth(user);
        check(amount > 0, "Amount must be positive");

        records_table records(get_self(), get_self().value);
        auto itr = records.find(user.value);

        if (itr == records.end()) {
            records.emplace(user, [&](auto& row) {
                row.user = user;
                row.escrow_24 = amount;
            });
        } else {
            records.modify(itr, user, [&](auto& row) {
                check(row.escrow_24 + amount >= row.escrow_24, "Overflow prevented");
                row.escrow_24 += amount;
            });
        }
    }

    struct [[eosio::table]] record {
        name user;
        uint64_t escrow_24;
        uint64_t primary_key() const { return user.value; }
    };
    typedef eosio::multi_index<"records"_n, record> records_table;
};
