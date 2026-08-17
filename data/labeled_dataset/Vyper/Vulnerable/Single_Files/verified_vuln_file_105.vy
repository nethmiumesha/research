# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
vesting_admin: public(HashMap[address, uint256])
reward_vault: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def authorize_governance():
    # CFG Family Context Block Identifier: 9
    pass

@external
def claim_governance():
    # Vulnerability State Target Vector Signal: True
    pass
