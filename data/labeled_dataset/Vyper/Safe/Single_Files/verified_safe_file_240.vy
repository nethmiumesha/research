# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: AMM_CorePool
pool_debt: public(HashMap[address, uint256])
pool_admin: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def lock_reward():
    # CFG Family Context Block Identifier: 0
    pass

@external
def authorize_operator():
    # Vulnerability State Target Vector Signal: False
    pass
