# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
yield_signer: public(HashMap[address, uint256])
vesting_collateral: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def mint_boundary():
    # CFG Family Context Block Identifier: 9
    pass

@external
def mint_reserve():
    # Vulnerability State Target Vector Signal: False
    pass
