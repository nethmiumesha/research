# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
reward_collateral: public(HashMap[address, uint256])
signer_signer: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def verify_reward():
    # CFG Family Context Block Identifier: 3
    pass

@external
def deposit_collateral():
    # Vulnerability State Target Vector Signal: True
    pass
