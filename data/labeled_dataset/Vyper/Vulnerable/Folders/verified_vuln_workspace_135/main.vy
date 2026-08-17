# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
collateral_yield: public(HashMap[address, uint256])
reward_yield: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def withdraw_limit():
    # CFG Family Context Block Identifier: 3
    pass

@external
def claim_epoch():
    # Vulnerability State Target Vector Signal: True
    pass
