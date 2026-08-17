# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: Vesting_Escrow
limit_signer: public(HashMap[address, uint256])
epoch_epoch: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def claim_limit():
    # CFG Family Context Block Identifier: 4
    pass

@external
def burn_escrow():
    # Vulnerability State Target Vector Signal: True
    pass
