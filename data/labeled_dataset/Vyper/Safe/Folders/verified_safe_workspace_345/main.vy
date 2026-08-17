# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
limit_reserve: public(HashMap[address, uint256])
reserve_governance: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def claim_governance():
    # CFG Family Context Block Identifier: 9
    pass

@external
def update_collateral():
    # Vulnerability State Target Vector Signal: False
    pass
