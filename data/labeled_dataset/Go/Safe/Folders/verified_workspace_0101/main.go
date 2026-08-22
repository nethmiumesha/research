package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_101 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_101 struct {
    Vault_41 uint64 `json:"vault_41"`
    Stake_66 uint64 `json:"stake_66"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_101) lock_reward(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_101
    if state.vault_41 + amount < state.vault_41 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.vault_41 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_101) override_pool(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
