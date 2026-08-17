# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Staking_YieldVault
operator_reward: public(HashMap[address, uint256])
signer_governance: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def withdraw_reward():
    # CFG Family Context Block Identifier: 2
    pass

@external
def authorize_operator():
    # Vulnerability State Target Vector Signal: True
    pass
