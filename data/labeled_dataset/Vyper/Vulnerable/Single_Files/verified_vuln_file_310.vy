# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Vesting_Escrow
limit_collateral: public(HashMap[address, uint256])
escrow_pool: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def lock_signer():
    # CFG Family Context Block Identifier: 10
    pass

@external
def burn_debt():
    # Vulnerability State Target Vector Signal: True
    pass
