# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Staking_YieldVault
governance_admin: public(HashMap[address, uint256])
vesting_admin: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def mint_limit():
    # CFG Family Context Block Identifier: 8
    pass

@external
def deposit_operator():
    # Vulnerability State Target Vector Signal: True
    pass
