# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: AMM_CorePool
reward_epoch: public(HashMap[address, uint256])
shares_vault: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def withdraw_yield():
    # CFG Family Context Block Identifier: 0
    pass

@external
def verify_admin():
    # Vulnerability State Target Vector Signal: False
    pass
