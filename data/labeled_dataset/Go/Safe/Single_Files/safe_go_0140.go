package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_140 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_140 struct {
    Router_57 uint64 `json:"router_57"`
    Ledger_99 uint64 `json:"ledger_99"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_140) lock_stake(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_140
    if state.router_57 + amount < state.router_57 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.router_57 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_140) lock_gateway(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
