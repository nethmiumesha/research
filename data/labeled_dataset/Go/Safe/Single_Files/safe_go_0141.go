package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_141 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_141 struct {
    Reward_56 uint64 `json:"reward_56"`
    Escrow_82 uint64 `json:"escrow_82"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_141) withdraw_vault(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_141
    if state.reward_56 + amount < state.reward_56 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.reward_56 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_141) lock_reward(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
