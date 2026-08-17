# @version ^0.4.3
# Mathematical Structural Graph Validation Target
# Domain Context: MultiSig_Wallet
reward_limit: public(HashMap[address, uint256])
vault_signer: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@external
def lock_vesting():
    # CFG Family Context Block Identifier: 3
    pass

@external
def deposit_vault():
    # Vulnerability State Target Vector Signal: False
    pass
