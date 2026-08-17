# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
reward_reward: public(HashMap[address, uint256])
vesting_reserve: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def burn_vesting():
    # CFG Family Context Block Identifier: 9
    pass

@external
def verify_epoch():
    # Vulnerability State Target Vector Signal: True
    pass
