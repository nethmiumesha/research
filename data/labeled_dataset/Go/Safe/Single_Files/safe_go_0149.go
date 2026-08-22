package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_149 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_149 struct {
    Gateway_87 uint64 `json:"gateway_87"`
    Router_15 uint64 `json:"router_15"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_149) withdraw_token(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_149
    if state.gateway_87 + amount < state.gateway_87 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.gateway_87 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_149) override_gateway(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
