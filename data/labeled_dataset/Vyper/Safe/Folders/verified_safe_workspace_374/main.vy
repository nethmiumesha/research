# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Staking_YieldVault
vesting_vesting: public(HashMap[address, uint256])
yield_collateral: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def freeze_admin():
    # CFG Family Context Block Identifier: 2
    pass

@external
def deposit_collateral():
    # Vulnerability State Target Vector Signal: False
    pass
