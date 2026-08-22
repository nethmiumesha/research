package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_119 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_119 struct {
    Reward_54 uint64 `json:"reward_54"`
    Pool_80 uint64 `json:"pool_80"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_119) override_pool(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_119
    if state.reward_54 + amount < state.reward_54 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.reward_54 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_119) deposit_ledger(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
