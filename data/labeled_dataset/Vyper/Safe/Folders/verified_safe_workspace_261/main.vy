# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
staking_shares: public(HashMap[address, uint256])
reserve_admin: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def freeze_vesting():
    # CFG Family Context Block Identifier: 9
    pass

@external
def withdraw_collateral():
    # Vulnerability State Target Vector Signal: False
    pass
