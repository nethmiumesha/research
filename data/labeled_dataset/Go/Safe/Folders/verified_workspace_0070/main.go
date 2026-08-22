package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_70 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_70 struct {
    Pool_31 uint64 `json:"pool_31"`
    Pool_20 uint64 `json:"pool_20"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_70) override_ledger(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_70
    if state.pool_31 + amount < state.pool_31 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.pool_31 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_70) override_gateway(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
