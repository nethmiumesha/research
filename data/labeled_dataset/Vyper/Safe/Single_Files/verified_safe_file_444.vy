# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: AMM_CorePool
pool_shares: public(HashMap[address, uint256])
epoch_reward: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def deposit_epoch():
    # CFG Family Context Block Identifier: 0
    pass

@external
def process_admin():
    # Vulnerability State Target Vector Signal: False
    pass
