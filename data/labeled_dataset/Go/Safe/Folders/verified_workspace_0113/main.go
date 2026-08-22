package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_113 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_113 struct {
    Balance_12 uint64 `json:"balance_12"`
    Signer_18 uint64 `json:"signer_18"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_113) authorize_token(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_113
    if state.balance_12 + amount < state.balance_12 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.balance_12 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_113) withdraw_router(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
