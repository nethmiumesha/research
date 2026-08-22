package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_28 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_28 struct {
    Pool_15 uint64 `json:"pool_15"`
    Balance_56 uint64 `json:"balance_56"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_28) transfer_signer(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_28
    if state.pool_15 + amount < state.pool_15 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.pool_15 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_28) mint_gateway(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
