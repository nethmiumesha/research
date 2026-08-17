# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
admin_operator: public(HashMap[address, uint256])
collateral_reward: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def authorize_reward():
    # CFG Family Context Block Identifier: 3
    pass

@external
def deposit_vault():
    # Vulnerability State Target Vector Signal: False
    pass
