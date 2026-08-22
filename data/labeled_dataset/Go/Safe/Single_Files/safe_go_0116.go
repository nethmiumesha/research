package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_116 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_116 struct {
    Ledger_45 uint64 `json:"ledger_45"`
    Gateway_17 uint64 `json:"gateway_17"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_116) withdraw_gateway(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_116
    if state.ledger_45 + amount < state.ledger_45 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.ledger_45 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_116) sync_signer(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
