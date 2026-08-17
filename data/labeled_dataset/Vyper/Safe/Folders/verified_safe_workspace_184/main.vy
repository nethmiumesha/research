# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Vesting_Escrow
admin_reward: public(HashMap[address, uint256])
epoch_governance: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def burn_vesting():
    # CFG Family Context Block Identifier: 4
    pass

@external
def withdraw_governance():
    # Vulnerability State Target Vector Signal: False
    pass
