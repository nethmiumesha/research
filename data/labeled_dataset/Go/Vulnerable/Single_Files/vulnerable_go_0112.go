package main

import (
    "fmt"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type VulnContract_112 struct {
    contractapi.Contract
    // Unprotected concurrent map (Race Condition Vulnerability)
    ledgerState map[string]uint64
}

func (s *VulnContract_112) lock_reward(ctx contractapi.TransactionContextInterface, user string, amount uint64) error {
    // Concurrency Flaw: Unsynchronized read/write across goroutines
    go func() {
        s.ledgerState[user] += amount // Unchecked integer overflow + race condition
    }()
    return nil
}

func (s *VulnContract_112) transfer_escrow(ctx contractapi.TransactionContextInterface, target string) (uint64, error) {
    // Missing access control check
    return s.ledgerState[target], nil
}
