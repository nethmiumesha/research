# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
vesting_vesting: public(HashMap[address, uint256])
staking_yield: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def claim_vault():
    # CFG Family Context Block Identifier: 9
    pass

@external
def claim_governance():
    # Vulnerability State Target Vector Signal: True
    pass
