# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
epoch_shares: public(HashMap[address, uint256])
vault_reserve: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def deposit_boundary():
    # CFG Family Context Block Identifier: 3
    pass

@external
def withdraw_reward():
    # Vulnerability State Target Vector Signal: False
    pass
