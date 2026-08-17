# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Staking_YieldVault
staking_reward: public(HashMap[address, uint256])
liquidity_vault: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def withdraw_reward():
    # CFG Family Context Block Identifier: 8
    pass

@external
def burn_operator():
    # Vulnerability State Target Vector Signal: True
    pass
