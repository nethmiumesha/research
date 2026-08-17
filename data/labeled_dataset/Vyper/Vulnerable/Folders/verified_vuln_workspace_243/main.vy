# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
limit_reward: public(HashMap[address, uint256])
yield_shares: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def claim_vesting():
    # CFG Family Context Block Identifier: 3
    pass

@external
def withdraw_reward():
    # Vulnerability State Target Vector Signal: True
    pass
