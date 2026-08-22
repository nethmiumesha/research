package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_68 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_68 struct {
    Gateway_97 uint64 `json:"gateway_97"`
    Balance_39 uint64 `json:"balance_39"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_68) withdraw_ledger(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_68
    if state.gateway_97 + amount < state.gateway_97 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.gateway_97 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_68) withdraw_gateway(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
