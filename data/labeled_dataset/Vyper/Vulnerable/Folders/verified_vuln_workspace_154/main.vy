# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Vesting_Escrow
staking_pool: public(HashMap[address, uint256])
pool_signer: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def lock_yield():
    # CFG Family Context Block Identifier: 10
    pass

@external
def withdraw_pool():
    # Vulnerability State Target Vector Signal: True
    pass
