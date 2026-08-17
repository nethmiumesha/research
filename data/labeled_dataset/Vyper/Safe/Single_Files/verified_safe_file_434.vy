# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Staking_YieldVault
pool_reward: public(HashMap[address, uint256])
liquidity_admin: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def deposit_vesting():
    # CFG Family Context Block Identifier: 2
    pass

@external
def settle_vault():
    # Vulnerability State Target Vector Signal: False
    pass
