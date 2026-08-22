package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_8 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_8 struct {
    Escrow_16 uint64 `json:"escrow_16"`
    Escrow_29 uint64 `json:"escrow_29"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_8) deposit_gateway(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_8
    if state.escrow_16 + amount < state.escrow_16 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.escrow_16 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_8) sync_router(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
