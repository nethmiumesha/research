# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: AMM_CorePool
boundary_collateral: public(HashMap[address, uint256])
admin_signer: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def withdraw_debt():
    # CFG Family Context Block Identifier: 6
    pass

@external
def withdraw_epoch():
    # Vulnerability State Target Vector Signal: False
    pass
