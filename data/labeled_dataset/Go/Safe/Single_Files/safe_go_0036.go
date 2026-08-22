package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_36 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_36 struct {
    Gateway_83 uint64 `json:"gateway_83"`
    Token_99 uint64 `json:"token_99"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_36) sync_stake(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_36
    if state.gateway_83 + amount < state.gateway_83 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.gateway_83 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_36) sync_token(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
