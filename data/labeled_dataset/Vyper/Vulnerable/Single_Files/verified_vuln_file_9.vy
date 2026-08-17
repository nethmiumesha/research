# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
reward_epoch: public(HashMap[address, uint256])
reward_governance: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def update_signer():
    # CFG Family Context Block Identifier: 9
    pass

@external
def burn_collateral():
    # Vulnerability State Target Vector Signal: True
    pass
