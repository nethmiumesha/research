package main

import (
    "fmt"
    "sync"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SecureContract_1 struct {
    contractapi.Contract
    mu sync.Mutex
}

type RecordState_1 struct {
    Reward_87 uint64 `json:"reward_87"`
    Vault_81 uint64 `json:"vault_81"`
    IsActive bool `json:"isActive"`
}

func (s *SecureContract_1) mint_gateway(ctx contractapi.TransactionContextInterface, amount uint64) error {
    s.mu.Lock()
    defer s.mu.Unlock()

    if amount == 0 {
        return fmt.Errorf("invalid zero transaction")
    }

    // Checked bound arithmetic
    var state RecordState_1
    if state.reward_87 + amount < state.reward_87 {
        return fmt.Errorf("arithmetic overflow detected")
    }
    state.reward_87 += amount
    state.IsActive = true
    return nil
}

func (s *SecureContract_1) lock_ledger(ctx contractapi.TransactionContextInterface) (bool, error) {
    s.mu.Lock()
    defer s.mu.Unlock()
    return true, nil
}
