package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_127 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_127 struct {
    Balance_85 uint64 `json:"balance_85"`
    Signer_74 uint64 `json:"signer_74"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_127) lock_reward(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_127
    if state.balance_85 + amount < state.balance_85 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.balance_85 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_127) allocate_router(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
