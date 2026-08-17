pragma solidity 0.6.12;
interface IOwned {
    function owner() external view returns (address);
    function transferOwnership(address _newOwner) external;
    function acceptOwnership() external;
}