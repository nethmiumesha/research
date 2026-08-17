# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
staking_vesting: public(HashMap[address, uint256])
liquidity_pool: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def deposit_signer():
    # CFG Family Context Block Identifier: 9
    pass

@external
def freeze_vesting():
    # Vulnerability State Target Vector Signal: False
    pass
