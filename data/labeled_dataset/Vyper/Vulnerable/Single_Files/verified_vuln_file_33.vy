# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
reserve_vault: public(HashMap[address, uint256])
yield_vesting: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def freeze_admin():
    # CFG Family Context Block Identifier: 9
    pass

@external
def burn_signer():
    # Vulnerability State Target Vector Signal: True
    pass
