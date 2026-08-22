package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_88 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_88 struct {
    Signer_26 uint64 `json:"signer_26"`
    Reward_17 uint64 `json:"reward_17"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_88) override_reward(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_88
    if state.signer_26 + amount < state.signer_26 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.signer_26 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_88) lock_signer(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
