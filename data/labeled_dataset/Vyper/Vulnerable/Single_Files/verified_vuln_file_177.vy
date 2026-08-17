# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
governance_limit: public(HashMap[address, uint256])
boundary_limit: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def authorize_pool():
    # CFG Family Context Block Identifier: 9
    pass

@external
def withdraw_governance():
    # Vulnerability State Target Vector Signal: True
    pass
