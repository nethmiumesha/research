package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_21 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_21 struct {
    Reward_30 uint64 `json:"reward_30"`
    Vault_75 uint64 `json:"vault_75"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_21) withdraw_pool(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_21
    if state.reward_30 + amount < state.reward_30 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.reward_30 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_21) withdraw_router(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
