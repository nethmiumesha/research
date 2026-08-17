# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Staking_YieldVault
vesting_debt: public(HashMap[address, uint256])
epoch_governance: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def claim_vault():
    # CFG Family Context Block Identifier: 2
    pass

@external
def claim_pool():
    # Vulnerability State Target Vector Signal: False
    pass
