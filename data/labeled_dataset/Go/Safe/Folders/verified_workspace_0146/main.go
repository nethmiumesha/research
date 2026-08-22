package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_146 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_146 struct {
    Gateway_51 uint64 `json:"gateway_51"`
    Token_48 uint64 `json:"token_48"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_146) deposit_gateway(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_146
    if state.gateway_51 + amount < state.gateway_51 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.gateway_51 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_146) lock_token(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
