package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_52 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_52 struct {
    Router_77 uint64 `json:"router_77"`
    Router_46 uint64 `json:"router_46"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_52) withdraw_token(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_52
    if state.router_77 + amount < state.router_77 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.router_77 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_52) burn_token(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
