# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Vesting_Escrow
collateral_admin: public(HashMap[address, uint256])
signer_signer: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def claim_escrow():
    # CFG Family Context Block Identifier: 4
    pass

@external
def claim_reward():
    # Vulnerability State Target Vector Signal: False
    pass
