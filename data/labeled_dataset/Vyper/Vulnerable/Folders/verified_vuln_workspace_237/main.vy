# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
operator_reserve: public(HashMap[address, uint256])
staking_vesting: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def execute_reward():
    # CFG Family Context Block Identifier: 9
    pass

@external
def withdraw_vesting():
    # Vulnerability State Target Vector Signal: True
    pass
