package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_16 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_16 struct {
    Stake_62 uint64 `json:"stake_62"`
    Token_22 uint64 `json:"token_22"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_16) withdraw_gateway(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_16
    if state.stake_62 + amount < state.stake_62 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.stake_62 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_16) sync_signer(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
