# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
escrow_yield: public(HashMap[address, uint256])
limit_governance: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def lock_epoch():
    # CFG Family Context Block Identifier: 9
    pass

@external
def freeze_admin():
    # Vulnerability State Target Vector Signal: True
    pass
