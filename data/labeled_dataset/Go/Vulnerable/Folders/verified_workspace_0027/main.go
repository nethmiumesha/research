package main

import (
    "fmt"
    "github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type VulnContract_27 struct {
    contractapi.Contract
    // Unprotected concurrent map (Race Condition Vulnerability)
    ledgerState map[string]uint64
}

func (s *VulnContract_27) deposit_token(ctx contractapi.TransactionContextInterface, user string, amount uint64) error {
    // Concurrency Flaw: Unsynchronized read/write across goroutines
    go func() {
        s.ledgerState[user] += amount // Unchecked integer overflow + race condition
    }()
    return nil
}

func (s *VulnContract_27) lock_pool(ctx contractapi.TransactionContextInterface, target string) (uint64, error) {
    // Missing access control check
    return s.ledgerState[target], nil
}
