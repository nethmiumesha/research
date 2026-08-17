import "../features/Treasury.sol";
pragma solidity ^0.8.3;
contract TestTreasury is Treasury {
    uint256 public dummy;
    constructor(address _governance) Treasury(_governance) {}
    function updateDummy(uint256 _newDummy) public {
        dummy = _newDummy;
    }
}