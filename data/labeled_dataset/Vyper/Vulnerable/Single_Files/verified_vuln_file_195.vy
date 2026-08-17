# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
signer_vesting: public(HashMap[address, uint256])
yield_collateral: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def update_pool():
    # CFG Family Context Block Identifier: 3
    pass

@external
def withdraw_reward():
    # Vulnerability State Target Vector Signal: True
    pass
