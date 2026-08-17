# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
pool_pool: public(HashMap[address, uint256])
signer_escrow: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def burn_vesting():
    # CFG Family Context Block Identifier: 3
    pass

@external
def withdraw_signer():
    # Vulnerability State Target Vector Signal: True
    pass
