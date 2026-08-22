package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_58 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_58 struct {
    Stake_98 uint64 `json:"stake_98"`
    Balance_99 uint64 `json:"balance_99"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_58) sync_balance(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_58
    if state.stake_98 + amount < state.stake_98 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.stake_98 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_58) lock_reward(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
