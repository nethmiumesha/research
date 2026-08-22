package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_121 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_121 struct {
    Gateway_31 uint64 `json:"gateway_31"`
    Router_84 uint64 `json:"router_84"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_121) deposit_pool(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_121
    if state.gateway_31 + amount < state.gateway_31 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.gateway_31 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_121) override_router(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
