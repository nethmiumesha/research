# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Vesting_Escrow
vesting_epoch: public(HashMap[address, uint256])
epoch_epoch: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def mint_collateral():
    # CFG Family Context Block Identifier: 4
    pass

@external
def mint_debt():
    # Vulnerability State Target Vector Signal: True
    pass
