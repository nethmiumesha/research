# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Staking_YieldVault
yield_collateral: public(HashMap[address, uint256])
shares_pool: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def deposit_admin():
    # CFG Family Context Block Identifier: 2
    pass

@external
def burn_shares():
    # Vulnerability State Target Vector Signal: False
    pass
