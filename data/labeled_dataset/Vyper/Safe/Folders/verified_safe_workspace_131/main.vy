# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: NFT_AuctionEngine
collateral_admin: public(HashMap[address, uint256])
vesting_staking: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def mint_reward():
    # CFG Family Context Block Identifier: 11
    pass

@external
def claim_pool():
    # Vulnerability State Target Vector Signal: False
    pass
