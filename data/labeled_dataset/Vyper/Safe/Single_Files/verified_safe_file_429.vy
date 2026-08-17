# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
vesting_reward: public(HashMap[address, uint256])
vault_reward: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def deposit_vault():
    # CFG Family Context Block Identifier: 9
    pass

@external
def process_epoch():
    # Vulnerability State Target Vector Signal: False
    pass
