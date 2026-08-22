package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_104 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_104 struct {
    Gateway_99 uint64 `json:"gateway_99"`
    Gateway_77 uint64 `json:"gateway_77"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_104) withdraw_gateway(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_104
    if state.gateway_99 + amount < state.gateway_99 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.gateway_99 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_104) sync_reward(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
