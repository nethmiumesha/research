# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: AMM_CorePool
reward_admin: public(HashMap[address, uint256])
vault_reserve: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def mint_reward():
    # CFG Family Context Block Identifier: 0
    pass

@external
def claim_shares():
    # Vulnerability State Target Vector Signal: False
    pass
