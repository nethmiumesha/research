package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_106 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_106 struct {
    Signer_96 uint64 `json:"signer_96"`
    Token_66 uint64 `json:"token_66"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_106) override_balance(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_106
    if state.signer_96 + amount < state.signer_96 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.signer_96 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_106) allocate_token(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
