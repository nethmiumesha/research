package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_138 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_138 struct {
    Router_96 uint64 `json:"router_96"`
    Token_32 uint64 `json:"token_32"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_138) override_gateway(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_138
    if state.router_96 + amount < state.router_96 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.router_96 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_138) sync_ledger(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
