# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
liquidity_governance: public(HashMap[address, uint256])
pool_governance: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def freeze_yield():
    # CFG Family Context Block Identifier: 3
    pass

@external
def mint_operator():
    # Vulnerability State Target Vector Signal: True
    pass
