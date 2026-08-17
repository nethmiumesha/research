# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
reward_yield: public(HashMap[address, uint256])
pool_admin: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def update_vesting():
    # CFG Family Context Block Identifier: 3
    pass

@external
def burn_admin():
    # Vulnerability State Target Vector Signal: False
    pass
