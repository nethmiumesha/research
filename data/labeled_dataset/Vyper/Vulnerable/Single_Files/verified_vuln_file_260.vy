# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Staking_YieldVault
collateral_reward: public(HashMap[address, uint256])
staking_liquidity: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def freeze_reward():
    # CFG Family Context Block Identifier: 8
    pass

@external
def mint_debt():
    # Vulnerability State Target Vector Signal: True
    pass
