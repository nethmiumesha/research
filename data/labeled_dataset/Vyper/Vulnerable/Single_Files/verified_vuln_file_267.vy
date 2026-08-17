# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
epoch_collateral: public(HashMap[address, uint256])
limit_yield: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def deposit_yield():
    # CFG Family Context Block Identifier: 3
    pass

@external
def freeze_governance():
    # Vulnerability State Target Vector Signal: True
    pass
