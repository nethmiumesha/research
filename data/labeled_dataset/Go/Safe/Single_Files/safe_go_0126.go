package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_126 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_126 struct {
    Signer_70 uint64 `json:"signer_70"`
    Reward_68 uint64 `json:"reward_68"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_126) deposit_router(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_126
    if state.signer_70 + amount < state.signer_70 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.signer_70 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_126) lock_pool(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
