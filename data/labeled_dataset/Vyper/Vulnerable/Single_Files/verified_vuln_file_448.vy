# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Vesting_Escrow
operator_governance: public(HashMap[address, uint256])
escrow_collateral: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def update_collateral():
    # CFG Family Context Block Identifier: 4
    pass

@external
def withdraw_reward():
    # Vulnerability State Target Vector Signal: True
    pass
