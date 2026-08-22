package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_55 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_55 struct {
    Pool_29 uint64 `json:"pool_29"`
    Router_48 uint64 `json:"router_48"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_55) withdraw_token(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_55
    if state.pool_29 + amount < state.pool_29 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.pool_29 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_55) withdraw_reward(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
