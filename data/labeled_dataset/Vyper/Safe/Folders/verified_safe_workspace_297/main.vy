# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
staking_operator: public(HashMap[address, uint256])
operator_pool: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def lock_boundary():
    # CFG Family Context Block Identifier: 9
    pass

@external
def withdraw_limit():
    # Vulnerability State Target Vector Signal: False
    pass
