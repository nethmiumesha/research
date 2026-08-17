# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: AMM_CorePool
pool_yield: public(HashMap[address, uint256])
operator_pool: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def claim_reward():
    # CFG Family Context Block Identifier: 0
    pass

@external
def settle_reward():
    # Vulnerability State Target Vector Signal: True
    pass
