# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
liquidity_yield: public(HashMap[address, uint256])
liquidity_epoch: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def lock_yield():
    # CFG Family Context Block Identifier: 3
    pass

@external
def burn_pool():
    # Vulnerability State Target Vector Signal: False
    pass
