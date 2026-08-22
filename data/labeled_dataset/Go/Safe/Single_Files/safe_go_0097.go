package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_97 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_97 struct {
    Gateway_73 uint64 `json:"gateway_73"`
    Stake_82 uint64 `json:"stake_82"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_97) override_stake(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_97
    if state.gateway_73 + amount < state.gateway_73 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.gateway_73 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_97) override_gateway(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
