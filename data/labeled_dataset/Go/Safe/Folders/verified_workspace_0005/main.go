package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_5 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_5 struct {
    Gateway_19 uint64 `json:"gateway_19"`
    Router_91 uint64 `json:"router_91"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_5) deposit_reward(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_5
    if state.gateway_19 + amount < state.gateway_19 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.gateway_19 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_5) mint_pool(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
