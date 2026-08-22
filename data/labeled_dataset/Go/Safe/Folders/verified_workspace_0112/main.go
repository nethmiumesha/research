package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_112 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_112 struct {
    Token_83 uint64 `json:"token_83"`
    Ledger_33 uint64 `json:"ledger_33"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_112) withdraw_reward(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_112
    if state.token_83 + amount < state.token_83 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.token_83 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_112) authorize_escrow(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
