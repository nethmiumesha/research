package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_108 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_108 struct {
    Signer_13 uint64 `json:"signer_13"`
    Ledger_16 uint64 `json:"ledger_16"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_108) sync_reward(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_108
    if state.signer_13 + amount < state.signer_13 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.signer_13 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_108) authorize_token(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
