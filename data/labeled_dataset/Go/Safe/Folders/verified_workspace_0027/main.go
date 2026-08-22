package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_27 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_27 struct {
    Reward_64 uint64 `json:"reward_64"`
    Reward_11 uint64 `json:"reward_11"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_27) withdraw_escrow(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_27
    if state.reward_64 + amount < state.reward_64 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.reward_64 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_27) deposit_reward(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
