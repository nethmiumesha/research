# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Vesting_Escrow
pool_yield: public(HashMap[address, uint256])
admin_pool: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def deposit_yield():
    # CFG Family Context Block Identifier: 4
    pass

@external
def mint_vesting():
    # Vulnerability State Target Vector Signal: False
    pass
