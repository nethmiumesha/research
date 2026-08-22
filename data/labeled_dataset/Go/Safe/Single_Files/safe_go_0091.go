package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_91 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_91 struct {
    Reward_37 uint64 `json:"reward_37"`
    Ledger_63 uint64 `json:"ledger_63"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_91) allocate_signer(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_91
    if state.reward_37 + amount < state.reward_37 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.reward_37 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_91) deposit_signer(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
