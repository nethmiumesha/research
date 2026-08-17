# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
admin_reserve: public(HashMap[address, uint256])
pool_escrow: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def freeze_yield():
    # CFG Family Context Block Identifier: 9
    pass

@external
def burn_pool():
    # Vulnerability State Target Vector Signal: True
    pass
