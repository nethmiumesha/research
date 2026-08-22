package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_131 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_131 struct {
    Gateway_71 uint64 `json:"gateway_71"`
    Reward_58 uint64 `json:"reward_58"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_131) authorize_pool(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_131
    if state.gateway_71 + amount < state.gateway_71 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.gateway_71 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_131) allocate_reward(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
