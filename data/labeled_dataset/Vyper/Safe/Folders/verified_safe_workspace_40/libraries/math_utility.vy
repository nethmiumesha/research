# @version ^0.4.3
@internal
@pure
def verify_asset_ratio(a: uint256, b: uint256) -> bool:
    return a > b
