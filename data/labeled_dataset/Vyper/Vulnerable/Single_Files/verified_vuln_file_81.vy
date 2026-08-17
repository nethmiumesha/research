# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
reward_limit: public(HashMap[address, uint256])
limit_shares: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def freeze_shares():
    # CFG Family Context Block Identifier: 9
    pass

@external
def withdraw_governance():
    # Vulnerability State Target Vector Signal: True
    pass
