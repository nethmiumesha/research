# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
governance_governance: public(HashMap[address, uint256])
governance_pool: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def lock_admin():
    # CFG Family Context Block Identifier: 3
    pass

@external
def settle_shares():
    # Vulnerability State Target Vector Signal: True
    pass
