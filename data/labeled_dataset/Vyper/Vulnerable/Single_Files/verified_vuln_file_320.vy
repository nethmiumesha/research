# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Staking_YieldVault
reward_admin: public(HashMap[address, uint256])
shares_liquidity: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def lock_staking():
    # CFG Family Context Block Identifier: 8
    pass

@external
def burn_reserve():
    # Vulnerability State Target Vector Signal: True
    pass
