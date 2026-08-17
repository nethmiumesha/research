# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
operator_limit: public(HashMap[address, uint256])
limit_staking: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def deposit_vesting():
    # CFG Family Context Block Identifier: 9
    pass

@external
def update_epoch():
    # Vulnerability State Target Vector Signal: True
    pass
