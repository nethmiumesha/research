pragma solidity 0.8.6;
import "../../libraries/Reserve.sol";
contract TestReserve {
    using Reserve for Reserve.Data;
    using Reserve for mapping(bytes32 => Reserve.Data);
    uint256 public timestamp;
    bytes32 public reserveId;
    mapping(bytes32 => Reserve.Data) public reserves;
    constructor() {}
    function res() public view returns (Reserve.Data memory) {
        return reserves[reserveId];
    }
    function beforeEach(
        string memory name,
        uint256 timestamp_,
        uint256 reserveRisky,
        uint256 reserveStable
    ) public {
        timestamp = timestamp_;
        bytes32 resId = keccak256(abi.encodePacked(name));
        reserveId = resId;
        reserves[resId] = Reserve.Data({
            reserveRisky: uint128(reserveRisky),
            reserveStable: uint128(reserveStable),
            liquidity: uint128(2e18),
            blockTimestamp: uint32(timestamp_),
            cumulativeRisky: 0,
            cumulativeStable: 0,
            cumulativeLiquidity: 0
        });
    }
    function _blockTimestamp() public view returns (uint32 blockTimestamp) {
        blockTimestamp = uint32(timestamp);
    }
    function step(uint256 timestep) public {
        timestamp += uint32(timestep);
    }
    function shouldUpdate(bytes32 resId) public returns (Reserve.Data memory) {
        reserves[resId].update(_blockTimestamp());
        return reserves[resId];
    }
    function shouldSwap(
        bytes32 resId,
        bool addXRemoveY,
        uint256 deltaIn,
        uint256 deltaOut
    ) public returns (Reserve.Data memory) {
        reserves[resId].swap(addXRemoveY, deltaIn, deltaOut, _blockTimestamp());
        return reserves[resId];
    }
    function shouldAllocate(
        bytes32 resId,
        uint256 delRisky,
        uint256 delStable,
        uint256 delLiquidity
    ) public returns (Reserve.Data memory) {
        reserves[resId].allocate(delRisky, delStable, delLiquidity, _blockTimestamp());
        return reserves[resId];
    }
    function shouldRemove(
        bytes32 resId,
        uint256 delRisky,
        uint256 delStable,
        uint256 delLiquidity
    ) public returns (Reserve.Data memory) {
        reserves[resId].remove(delRisky, delStable, delLiquidity, _blockTimestamp());
        return reserves[resId];
    }
    function update(
        bytes32 resId,
        uint256 risky,
        uint256 stable,
        uint256 liquidity,
        uint32 blockTimestamp
    ) public returns (Reserve.Data memory) {
        reserves[resId].cumulativeRisky = risky;
        reserves[resId].cumulativeStable = stable;
        reserves[resId].cumulativeLiquidity = liquidity;
        reserves[resId].blockTimestamp = blockTimestamp;
        return reserves[resId];
    }
}