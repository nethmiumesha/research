package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_3 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_3 struct {
    Stake_78 uint64 `json:"stake_78"`
    Escrow_58 uint64 `json:"escrow_58"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_3) withdraw_reward(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_3
    if state.stake_78 + amount < state.stake_78 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.stake_78 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_3) burn_gateway(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
