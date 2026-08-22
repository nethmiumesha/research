package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_118 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_118 struct {
    Stake_13 uint64 `json:"stake_13"`
    Signer_80 uint64 `json:"signer_80"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_118) override_signer(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_118
    if state.stake_13 + amount < state.stake_13 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.stake_13 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_118) allocate_reward(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
